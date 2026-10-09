const { test, before, after, beforeEach } = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
require('firebase/compat/firestore');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const { doc, setDoc, getDoc, getDocs, collection, updateDoc, serverTimestamp, writeBatch } = require('firebase/firestore');
let env;
const id = '0123456789abcdef0123456789abcdef';
const root = `rooms/${id}`;
const playback = { current: null, queue: [], isPlaying: false, progressMs: 0, canControl: false };

before(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-bingusfy', firestore: {
    host: '127.0.0.1', port: 8081, rules: fs.readFileSync(path.join(__dirname, '../../firestore.rules'), 'utf8'),
  } });
});
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    const db = context.firestore();
    await setDoc(doc(db, root), { ownerUid: 'owner', status: 'open', artists: ['A'], playback,
      settings: {gridSize: 5, blankPercent: 20, freeCenter: true} });
    await setDoc(doc(db, `${root}/participants/owner`), { name: 'Host', role: 'owner' });
    await setDoc(doc(db, `${root}/participants/guest`), { name: 'Guest', role: 'guest' });
    await setDoc(doc(db, `${root}/boards/guest`), { tiles: [], marks: [] });
  });
});

test('guest reads room and participants but cannot publish music or become owner', async () => {
  const db = env.authenticatedContext('guest').firestore();
  await assertSucceeds(getDoc(doc(db, root)));
  await assertSucceeds(getDocs(collection(db, `${root}/participants`)));
  await assertFails(updateDoc(doc(db, root), { playback, syncedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(db, root), { ownerUid: 'guest' }));
  await assertFails(setDoc(doc(db, `${root}/participants/guest`), { name: 'Guest', role: 'owner' }));
  await assertFails(getDocs(collection(db, 'rooms')));
});

test('only owner publishes safe playback fields; ownership and settings stay immutable', async () => {
  const db = env.authenticatedContext('owner').firestore();
  await assertSucceeds(updateDoc(doc(db, root), { playback, syncedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(db, root), { playback: { ...playback, access_token: 'secret' }, syncedAt: serverTimestamp() }));
  await assertFails(updateDoc(doc(db, root), { ownerUid: 'other' }));
  await assertFails(updateDoc(doc(db, root), { artists: ['Changed'] }));
});

test('members see shared boards but strangers cannot read or forge membership', async () => {
  const guest = env.authenticatedContext('guest').firestore();
  const stranger = env.authenticatedContext('stranger').firestore();
  await assertSucceeds(getDoc(doc(guest, `${root}/boards/guest`)));
  await assertSucceeds(getDocs(collection(guest, `${root}/boards`)));
  await assertSucceeds(getDocs(collection(env.authenticatedContext('owner').firestore(), `${root}/boards`)));
  await assertFails(getDocs(collection(stranger, `${root}/boards`)));
  await assertFails(getDoc(doc(stranger, `${root}/boards/guest`)));
  await assertFails(getDocs(collection(stranger, `${root}/participants`)));
  await assertFails(setDoc(doc(stranger, `${root}/participants/stranger`), { name: 'Fake', role: 'guest' }));
  await assertFails(updateDoc(doc(guest, `${root}/boards/guest`), { marks: [true] }));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), root)));
});

test('closed room refuses owner playback updates', async () => {
  await env.withSecurityRulesDisabled(context => updateDoc(doc(context.firestore(), root), { status: 'closed' }));
  const db = env.authenticatedContext('owner').firestore();
  await assertFails(updateDoc(doc(db, root), { playback, syncedAt: serverTimestamp() }));
});

function board(grid = 5) {
  const cells = Array.from({length: grid * grid}, () => 'A');
  if (grid % 2) cells[Math.floor(cells.length / 2)] = '__BINGUS_FREE__';
  return {gridSize: grid, name: 'Guest', cells, marks: cells.map(cell => cell === '__BINGUS_FREE__')};
}
test('owner creates room and identity atomically, cannot impersonate another creator', async () => {
  const db = env.authenticatedContext('creator').firestore();
  const newRoot = 'rooms/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const data = {ownerUid: 'creator', status: 'open', artists: ['A'],
    settings: {gridSize: 5, blankPercent: 20, freeCenter: true}, playback,
    createdAt: serverTimestamp(), syncedAt: serverTimestamp()};
  const batch = writeBatch(db);
  batch.set(doc(db, newRoot), data);
  batch.set(doc(db, newRoot + '/participants/creator'), {name: 'Host', role: 'owner', joinedAt: serverTimestamp()});
  batch.set(doc(db, newRoot + '/boards/creator'), {...board(), name: 'Host'});
  await assertSucceeds(batch.commit());
  await assertFails(setDoc(doc(db, 'rooms/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'), {...data, ownerUid: 'someone-else'}));
});

test('guest joins with private table, marks it, and leaves atomically; cannot alter tiles or role', async () => {
  const db = env.authenticatedContext('new-guest').firestore();
  const memberRef = doc(db, root + '/participants/new-guest');
  const boardRef = doc(db, root + '/boards/new-guest');
  const value = board();
  value.name = 'New Guest';
  const batch = writeBatch(db);
  batch.set(memberRef, {name: 'New Guest', role: 'guest', joinedAt: serverTimestamp()});
  batch.set(boardRef, value);
  await assertSucceeds(batch.commit());
  const marked = [...value.marks]; marked[0] = true;
  await assertSucceeds(updateDoc(boardRef, {marks: marked}));
  await assertFails(updateDoc(boardRef, {cells: value.cells.map(() => 'Foreign artist')}));
  const badMarks = [...marked]; badMarks[12] = false;
  await assertFails(updateDoc(boardRef, {marks: badMarks}));
  await assertFails(updateDoc(memberRef, {role: 'owner'}));
  const leave = writeBatch(db); leave.delete(boardRef); leave.delete(memberRef);
  await assertSucceeds(leave.commit());
});

test('every supported grid accepts a valid table; forged artists and pre-marked tables fail', async () => {
  for (const grid of [3, 4, 5]) {
    await env.withSecurityRulesDisabled(context => updateDoc(doc(context.firestore(), root),
      {settings: {gridSize: grid, blankPercent: 20, freeCenter: true}}));
    const db = env.authenticatedContext('guest-' + grid).firestore();
    const memberRef = doc(db, root + '/participants/guest-' + grid);
    const boardRef = doc(db, root + '/boards/guest-' + grid);
    const join = value => { const batch = writeBatch(db);
      batch.set(memberRef, {name: 'Guest', role: 'guest', joinedAt: serverTimestamp()});
      batch.set(boardRef, value); return batch.commit(); };
    const forged = board(grid); forged.cells[0] = 'Foreign artist';
    await assertFails(join(forged));
    const marked = board(grid); marked.marks[0] = true;
    await assertFails(join(marked));
    await assertSucceeds(join(board(grid)));
  }
});

test('guests cannot close room, mark another table, or join after closure', async () => {
  const db = env.authenticatedContext('guest').firestore();
  await assertFails(updateDoc(doc(db, root), {status: 'closed', closedAt: serverTimestamp()}));
  await assertFails(updateDoc(doc(db, root + '/boards/other'), {marks: [true]}));
  const owner = env.authenticatedContext('owner').firestore();
  await assertSucceeds(updateDoc(doc(owner, root), {status: 'closed', closedAt: serverTimestamp()}));
  const fresh = env.authenticatedContext('fresh').firestore();
  const join = writeBatch(fresh);
  join.set(doc(fresh, root + '/participants/fresh'), {name: 'Fresh', role: 'guest', joinedAt: serverTimestamp()});
  join.set(doc(fresh, root + '/boards/fresh'), board());
  await assertFails(join.commit());
});
