import { AccessToken } from 'livekit-server-sdk';

export default async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });
  try {
    const { identity, room } = req.body || {};
    if (typeof identity !== 'string' || typeof room !== 'string' || !identity.trim() || !room.trim()) return res.status(400).json({ error: 'identity and room are required' });
    if (!process.env.LIVEKIT_API_KEY || !process.env.LIVEKIT_API_SECRET) return res.status(500).json({ error: 'LiveKit environment variables are missing' });
    const token = new AccessToken(process.env.LIVEKIT_API_KEY, process.env.LIVEKIT_API_SECRET, { identity: identity.slice(0, 100), ttl: '2h' });
    token.addGrant({ roomJoin: true, room: room.slice(0, 120), canPublish: true, canSubscribe: true, canPublishData: true });
    return res.status(200).json({ token: await token.toJwt() });
  } catch (e) { return res.status(500).json({ error: 'Could not create LiveKit token' }); }
}
