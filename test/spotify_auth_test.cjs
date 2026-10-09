const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { webcrypto } = require('node:crypto');
const vm = require('node:vm');

const source = readFileSync(require('node:path').join(__dirname, '../web/spotify_auth.js'), 'utf8');
const redirect = 'http://127.0.0.1:8080/';
function browser() {
  const storage = new Map();
  const calls = [];
  const context = {
    URL, URLSearchParams, TextEncoder, Uint8Array, crypto: webcrypto,
    btoa: text => Buffer.from(text, 'binary').toString('base64'),
    sessionStorage: {
      setItem: (key, value) => storage.set(key, value),
      getItem: key => storage.get(key) ?? null,
      removeItem: key => storage.delete(key),
    },
    location: { href: redirect, origin: 'http://127.0.0.1:8080', pathname: '/', hash: '', assign(url) { this.target = url; } },
    history: { state: { flutter: { serialCount: 1 } }, replaceState(state) { this.lastState = state; context.location.href = redirect; } },
    fetch: async (url, options) => {
      calls.push({ url, options });
      return { ok: true, json: async () => ({ access_token: 'test-access', refresh_token: 'test-refresh', expires_in: 3600 }) };
    },
  };
  context.window = context;
  vm.runInNewContext(source, context);
  return { context, storage, calls };
}

test('authorization uses S256 PKCE and exchanges the callback with the matching verifier', async () => {
  const { context: c, storage, calls } = browser();
  await c.bingusSpotifySignIn('test-client', redirect);
  const authorization = new URL(c.location.target);
  const pending = JSON.parse(storage.get('bingusfy.spotify.pending'));
  assert.equal(authorization.origin, 'https://accounts.spotify.com');
  assert.equal(authorization.searchParams.get('code_challenge_method'), 'S256');
  assert.equal(authorization.searchParams.get('code_challenge'), Buffer.from(await webcrypto.subtle.digest('SHA-256', new TextEncoder().encode(pending.verifier))).toString('base64url'));
  assert.equal(authorization.searchParams.get('state'), pending.state);
  assert.equal(authorization.searchParams.get('scope'), 'user-read-currently-playing user-read-playback-state user-modify-playback-state');
  c.location.href = `${redirect}?code=test-code&state=${pending.state}`;
  assert.equal(await c.bingusSpotifyRestore('test-client', redirect), true);
  assert.equal(calls[0].options.body.get('code_verifier'), pending.verifier);
  assert.equal(calls[0].options.body.get('grant_type'), 'authorization_code');
  assert.equal(storage.has('bingusfy.spotify.pending'), false);
  assert.equal(c.location.href, redirect);
  assert.equal(c.history.lastState, c.history.state);
  assert.equal(await c.bingusSpotifyRestore('test-client', redirect), true);
  assert.equal(calls.length, 1);
});

test('invalid or expired state never exchanges a code', async () => {
  for (const expired of [false, true]) {
    const { context: c, storage, calls } = browser();
    await c.bingusSpotifySignIn('test-client', redirect);
    const pending = JSON.parse(storage.get('bingusfy.spotify.pending'));
    if (expired) {
      pending.createdAt -= 610000;
      storage.set('bingusfy.spotify.pending', JSON.stringify(pending));
    }
    c.location.href = `${redirect}?code=test-code&state=${expired ? pending.state : 'wrong'}`;
    await assert.rejects(c.bingusSpotifyRestore('test-client', redirect), /inválida/);
    assert.equal(calls.length, 0);
    assert.equal(storage.has('bingusfy.spotify.pending'), false);
  }
});

test('denied authorization clears the pending attempt without calling token endpoint', async () => {
  const { context: c, storage, calls } = browser();
  await c.bingusSpotifySignIn('test-client', redirect);
  const { state } = JSON.parse(storage.get('bingusfy.spotify.pending'));
  c.location.href = `${redirect}?error=access_denied&state=${state}`;
  await assert.rejects(c.bingusSpotifyRestore('test-client', redirect), /cancelou/);
  assert.equal(calls.length, 0);
  assert.equal(storage.has('bingusfy.spotify.pending'), false);
});

test('expired token refreshes and failed refresh removes the session', async () => {
  const { context: c, storage, calls } = browser();
  const session = { clientId: 'test-client', access_token: 'expired', refresh_token: 'refresh', expiresAt: 0 };
  storage.set('bingusfy.spotify.session', JSON.stringify(session));
  assert.equal(await c.bingusSpotifyRestore('test-client', redirect), true);
  assert.equal(calls[0].options.body.get('grant_type'), 'refresh_token');
  storage.set('bingusfy.spotify.session', JSON.stringify(session));
  c.fetch = async () => ({ ok: false });
  assert.equal(await c.bingusSpotifyRestore('test-client', redirect), false);
  assert.equal(storage.has('bingusfy.spotify.session'), false);
});

test('missing configuration, localhost, and foreign redirect origins cannot begin authorization', async () => {
  const { context: c } = browser();
  assert.equal(await c.bingusSpotifyRestore('', ''), false);
  for (const [id, uri] of [['', redirect], ['test-client', 'http://localhost:8080/'], ['test-client', 'https://other.example/']]) {
    await assert.rejects(c.bingusSpotifySignIn(id, uri));
    assert.equal(c.location.target, undefined);
  }
});

function authorize(storage) {
  storage.set('bingusfy.spotify.session', JSON.stringify({ clientId: 'test-client', access_token: 'access', refresh_token: 'refresh', expiresAt: Date.now() + 3600000 }));
}

const response = (status, data, retryAfter) => ({
  ok: status >= 200 && status < 300, status,
  headers: { get: () => retryAfter ?? null },
  json: async () => data,
});

test('playback reads both endpoints with user token and returns current and queue', async () => {
  const { context: c, storage } = browser();
  authorize(storage);
  const calls = [];
  c.fetch = async (url, options) => {
    calls.push(url);
    assert.equal(options.headers.Authorization, 'Bearer access');
    return url.endsWith('/queue')
      ? response(200, { queue: [{ type: 'track', name: 'Next' }] })
      : response(200, { item: { type: 'track', name: 'Now' }, is_playing: false });
  };
  const data = JSON.parse(await c.bingusSpotifyPlayback('test-client', redirect));
  assert.equal(data.current.name, 'Now');
  assert.equal(data.isPlaying, false);
  assert.equal(data.queue[0].name, 'Next');
  assert.equal(calls.length, 2);
});

test('no playback and empty queue return an empty snapshot', async () => {
  const { context: c, storage } = browser();
  authorize(storage);
  c.fetch = async () => response(204);
  assert.deepEqual(JSON.parse(await c.bingusSpotifyPlayback('test-client', redirect)), { queue: [], current: null, isPlaying: null, progressMs: 0, canControl: false });
});

test('401 renews token once; repeated 401 signs out', async () => {
  for (const succeeds of [true, false]) {
    const { context: c, storage } = browser();
    authorize(storage);
    let tokenCalls = 0, apiCalls = 0;
    c.fetch = async (url, options) => {
      if (url.endsWith('/api/token')) {
        tokenCalls++;
        assert.equal(options.body.get('grant_type'), 'refresh_token');
        return response(200, { access_token: 'new-access', expires_in: 3600 });
      }
      apiCalls++;
      return succeeds && options.headers.Authorization === 'Bearer new-access'
        ? response(200, { queue: [], item: null }) : response(401);
    };
    const data = JSON.parse(await c.bingusSpotifyPlayback('test-client', redirect));
    assert.equal(tokenCalls, 1);
    assert.equal(apiCalls, 4);
    if (succeeds) assert.deepEqual(data.queue, []);
    else {
      assert.equal(data.error, 'session_expired');
      assert.equal(storage.has('bingusfy.spotify.session'), false);
    }
  }
});

test('403, 429 and network failures are reported without retry loops', async () => {
  for (const [status, expected] of [[403, 'forbidden'], [429, 'rate_limited'], [500, 'unavailable']]) {
    const { context: c, storage } = browser();
    authorize(storage);
    let calls = 0;
    c.fetch = async () => { calls++; return response(status, null, '45'); };
    const data = JSON.parse(await c.bingusSpotifyPlayback('test-client', redirect));
    assert.equal(data.error, expected);
    assert.equal(calls, 2);
    if (status === 429) assert.equal(data.retryAfter, 45);
  }
  const { context: c, storage } = browser();
  authorize(storage);
  c.fetch = async () => { throw new Error('offline'); };
  assert.equal(JSON.parse(await c.bingusSpotifyPlayback('test-client', redirect)).error, 'unavailable');
});

test('missing session prevents API access and sign out clears OAuth storage', async () => {
  const { context: c, storage, calls } = browser();
  assert.equal(JSON.parse(await c.bingusSpotifyPlayback('test-client', redirect)).error, 'session_expired');
  assert.equal(calls.length, 0);
  authorize(storage);
  storage.set('bingusfy.spotify.pending', 'test-pending');
  c.bingusSpotifySignOut();
  assert.equal(storage.size, 0);
});

test('controls send exactly one command with the correct endpoint and method', async () => {
  for (const [action, method] of [['next', 'POST'], ['previous', 'POST'], ['play', 'PUT'], ['pause', 'PUT']]) {
    const { context: c, storage } = browser();
    authorize(storage);
    let calls = 0;
    c.fetch = async (url, options) => {
      calls++;
      assert.equal(url, `https://api.spotify.com/v1/me/player/${action}`);
      assert.equal(options.method, method);
      assert.equal(options.headers.Authorization, 'Bearer access');
      assert.equal(options.body, undefined);
      return response(204);
    };
    assert.deepEqual(JSON.parse(await c.bingusSpotifyControl('test-client', redirect, action)), { ok: true });
    assert.equal(calls, 1);
    assert.equal(JSON.parse(await c.bingusSpotifyControl('test-client', redirect, 'constructor')).error, 'invalid_action');
    assert.equal(calls, 1);
  }
});

test('control failures never repeat skip commands except for a rejected token', async () => {
  for (const [status, expected] of [[403, 'control_forbidden'], [404, 'no_device'], [429, 'rate_limited'], [500, 'control_unavailable']]) {
    const { context: c, storage } = browser();
    authorize(storage);
    let calls = 0;
    c.fetch = async () => { calls++; return response(status, null, '45'); };
    const data = JSON.parse(await c.bingusSpotifyControl('test-client', redirect, 'next'));
    assert.equal(data.error, expected);
    assert.equal(calls, 1);
    if (status === 429) assert.equal(data.retryAfter, 45);
  }
  const { context: c, storage } = browser();
  authorize(storage);
  let calls = 0;
  c.fetch = async () => { calls++; throw new Error('offline'); };
  assert.equal(JSON.parse(await c.bingusSpotifyControl('test-client', redirect, 'next')).error, 'control_unavailable');
  assert.equal(calls, 1);
});

test('control renews rejected token once and signs out if still rejected', async () => {
  for (const succeeds of [true, false]) {
    const { context: c, storage } = browser();
    authorize(storage);
    let tokenCalls = 0, commands = 0;
    c.fetch = async (url, options) => {
      if (url.endsWith('/api/token')) {
        tokenCalls++;
        return response(200, { access_token: 'renewed', expires_in: 3600 });
      }
      commands++;
      return response(succeeds && options.headers.Authorization === 'Bearer renewed' ? 204 : 401);
    };
    const data = JSON.parse(await c.bingusSpotifyControl('test-client', redirect, 'next'));
    assert.equal(tokenCalls, 1);
    assert.equal(commands, 2);
    if (succeeds) assert.equal(data.ok, true);
    else {
      assert.equal(data.error, 'session_expired');
      assert.equal(storage.has('bingusfy.spotify.session'), false);
    }
  }
});

test('playback reports granted control scope and progress', async () => {
  const { context: c, storage } = browser();
  authorize(storage);
  const session = JSON.parse(storage.get('bingusfy.spotify.session'));
  session.scope = 'user-modify-playback-state user-read-playback-state';
  storage.set('bingusfy.spotify.session', JSON.stringify(session));
  c.fetch = async () => response(200, { queue: [], progress_ms: 12000, is_playing: true });
  const data = JSON.parse(await c.bingusSpotifyPlayback('test-client', redirect));
  assert.equal(data.canControl, true);
  assert.equal(data.progressMs, 12000);
});
