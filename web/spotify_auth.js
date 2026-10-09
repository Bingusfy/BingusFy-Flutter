// Browser-only Spotify Authorization Code flow with PKCE. No client secret.
(() => {
  const pendingKey = 'bingusfy.spotify.pending';
  const sessionKey = 'bingusfy.spotify.session';
  const encode = bytes => btoa(String.fromCharCode(...bytes)).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
  const random = () => encode(crypto.getRandomValues(new Uint8Array(32)));

  function validate(clientId, redirectUri) {
    if (!clientId || !redirectUri) throw new Error('O login com Spotify ainda não está configurado.');
    const uri = new URL(redirectUri);
    if (uri.protocol !== 'https:' && !(uri.protocol === 'http:' && ['127.0.0.1', '[::1]'].includes(uri.hostname))) {
      throw new Error('A URL de retorno precisa usar HTTPS ou o endereço local 127.0.0.1.');
    }
    if (uri.hash || uri.search || uri.origin !== location.origin) throw new Error('A URL de retorno deve apontar para este site, sem query ou fragmento.');
  }

  async function requestToken(body) {
    const response = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams(body),
    });
    if (!response.ok) throw new Error('Não foi possível concluir o login com Spotify. Tente novamente.');
    const token = await response.json();
    if (!token.access_token || !Number.isFinite(token.expires_in)) throw new Error('Resposta inválida do Spotify.');
    return token;
  }

  window.bingusSpotifySignIn = async (clientId, redirectUri) => {
    validate(clientId, redirectUri);
    const verifier = random(), state = random();
    const challenge = encode(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(verifier))));
    sessionStorage.setItem(pendingKey, JSON.stringify({ verifier, state, clientId, redirectUri, createdAt: Date.now() }));
    const params = new URLSearchParams({
      client_id: clientId, response_type: 'code', redirect_uri: redirectUri,
      code_challenge_method: 'S256', code_challenge: challenge, state,
      scope: 'user-read-currently-playing user-read-playback-state user-modify-playback-state',
    });
    location.assign(`https://accounts.spotify.com/authorize?${params}`);
  };

  window.bingusSpotifyRestore = async (clientId, redirectUri, forceRefresh = false) => {
    if (!clientId || !redirectUri) return false;
    validate(clientId, redirectUri);
    const callback = new URL(location.href);
    if (callback.searchParams.has('code') || callback.searchParams.has('error')) {
      const pending = JSON.parse(sessionStorage.getItem(pendingKey) || 'null');
      sessionStorage.removeItem(pendingKey);
      // Preserve Flutter's browser history metadata when removing OAuth params.
      history.replaceState(history.state, '', location.pathname + location.hash);
      if (!pending || pending.state !== callback.searchParams.get('state') || pending.clientId !== clientId || pending.redirectUri !== redirectUri || Date.now() - pending.createdAt > 600000) {
        throw new Error('A sessão de login expirou ou é inválida. Entre novamente.');
      }
      if (callback.searchParams.has('error')) throw new Error('Você cancelou a autorização do Spotify.');
      const token = await requestToken({
        client_id: clientId, grant_type: 'authorization_code',
        code: callback.searchParams.get('code'), redirect_uri: redirectUri, code_verifier: pending.verifier,
      });
      sessionStorage.setItem(sessionKey, JSON.stringify({ ...token, clientId, expiresAt: Date.now() + token.expires_in * 1000 }));
      return true;
    }
    const session = JSON.parse(sessionStorage.getItem(sessionKey) || 'null');
    if (!session || session.clientId !== clientId) return false;
    if (!forceRefresh && session.access_token && session.expiresAt > Date.now() + 30000) return true;
    if (!session.refresh_token) {
      sessionStorage.removeItem(sessionKey);
      return false;
    }
    try {
      const token = await requestToken({ client_id: clientId, grant_type: 'refresh_token', refresh_token: session.refresh_token });
      sessionStorage.setItem(sessionKey, JSON.stringify({ ...session, ...token, expiresAt: Date.now() + token.expires_in * 1000 }));
      return true;
    } catch {
      sessionStorage.removeItem(sessionKey);
      return false;
    }
  };

  window.bingusSpotifySignOut = () => {
    sessionStorage.removeItem(pendingKey);
    sessionStorage.removeItem(sessionKey);
  };

  window.bingusSpotifyPlayback = async (clientId, redirectUri) => {
    const result = data => JSON.stringify(data);
    try {
      if (!await window.bingusSpotifyRestore(clientId, redirectUri)) return result({ error: 'session_expired' });
      const read = async () => {
        const session = JSON.parse(sessionStorage.getItem(sessionKey));
        const headers = { Authorization: `Bearer ${session.access_token}` };
        return Promise.all([
          fetch('https://api.spotify.com/v1/me/player/queue', { headers }),
          fetch('https://api.spotify.com/v1/me/player/currently-playing', { headers }),
        ]);
      };
      let responses = await read();
      if (responses.some(response => response.status === 401)) {
        if (!await window.bingusSpotifyRestore(clientId, redirectUri, true)) return result({ error: 'session_expired' });
        responses = await read();
      }
      if (responses.some(response => response.status === 401)) {
        window.bingusSpotifySignOut();
        return result({ error: 'session_expired' });
      }
      const limited = responses.find(response => response.status === 429);
      if (limited) return result({ error: 'rate_limited', retryAfter: Number(limited.headers.get('Retry-After')) || 30 });
      if (responses.some(response => response.status === 403)) return result({ error: 'forbidden' });
      if (responses.some(response => !response.ok && response.status !== 204)) return result({ error: 'unavailable' });
      const [queue, playback] = await Promise.all(responses.map(response => response.status === 204 ? null : response.json()));
      const session = JSON.parse(sessionStorage.getItem(sessionKey));
      return result({ queue: queue?.queue || [], current: playback?.item ?? queue?.currently_playing ?? null, isPlaying: playback?.is_playing ?? null, progressMs: playback?.progress_ms ?? 0, canControl: (session?.scope || '').split(' ').includes('user-modify-playback-state') });
    } catch {
      return result({ error: 'unavailable' });
    }
  };

  window.bingusSpotifyControl = async (clientId, redirectUri, action) => {
    const paths = { next: ['POST', 'next'], previous: ['POST', 'previous'], play: ['PUT', 'play'], pause: ['PUT', 'pause'] };
    const result = data => JSON.stringify(data);
    if (!Object.hasOwn(paths, action)) return result({ error: 'invalid_action' });
    try {
      if (!await window.bingusSpotifyRestore(clientId, redirectUri)) return result({ error: 'session_expired' });
      const send = () => {
        const session = JSON.parse(sessionStorage.getItem(sessionKey));
        return fetch(`https://api.spotify.com/v1/me/player/${paths[action][1]}`, {
          method: paths[action][0], headers: { Authorization: `Bearer ${session.access_token}` },
        });
      };
      let response = await send();
      // Retry only an explicitly rejected token, never a network failure:
      // repeating a successful next/previous command could skip two tracks.
      if (response.status === 401) {
        if (!await window.bingusSpotifyRestore(clientId, redirectUri, true)) return result({ error: 'session_expired' });
        response = await send();
      }
      if (response.status === 401) {
        window.bingusSpotifySignOut();
        return result({ error: 'session_expired' });
      }
      if (response.status === 403) return result({ error: 'control_forbidden' });
      if (response.status === 404) return result({ error: 'no_device' });
      if (response.status === 429) return result({ error: 'rate_limited', retryAfter: Number(response.headers.get('Retry-After')) || 30 });
      if (!response.ok) return result({ error: 'control_unavailable' });
      return result({ ok: true });
    } catch {
      return result({ error: 'control_unavailable' });
    }
  };
})();
