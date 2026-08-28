import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import prisma from './db/prisma';
import authRoutes from './routes/authRoutes';
import insightRoutes from './routes/insightRoutes';
import userRoutes from './routes/userRoutes';
import graphRoutes from './routes/graphRoutes';
import eventRoutes from './routes/eventRoutes';
import voiceRoutes from './routes/voiceRoutes';
import actionRoutes from './routes/actionRoutes';
import chatRoutes from './routes/chatRoutes';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Routes
app.use('/api/auth/google', authRoutes);
app.use('/api/insights', insightRoutes);
app.use('/api/users', userRoutes);
app.use('/api/graph', graphRoutes);
app.use('/api/events', eventRoutes);
app.use('/api/voice', voiceRoutes);
app.use('/api/actions', actionRoutes);
app.use('/api/chat', chatRoutes);

// Image proxy to bypass CanvasKit CORS for Google Profile Pictures
app.get('/api/image-proxy', async (req, res) => {
  try {
    const url = req.query.url as string;
    if (!url) {
      return res.status(400).send('URL is required');
    }
    const fetch = (await import('node-fetch')).default;
    const response = await fetch(url);
    if (!response.ok) throw new Error('Failed to fetch image');
    const buffer = await response.buffer();
    res.set('Content-Type', response.headers.get('content-type') || 'image/jpeg');
    res.set('Cache-Control', 'public, max-age=86400');
    res.send(buffer);
  } catch (error) {
    res.status(500).send('Error proxying image');
  }
});

// Health check
app.get('/health', async (_req, res) => {
  try {
    const userCount = await prisma.user.count();
    const transactionCount = await prisma.transaction.count();
    const obligationCount = await prisma.obligation.count();
    const insightCount = await prisma.insight.count();

    res.json({
      status: 'ok',
      service: 'Autonomous Financial Management Agent API',
      database: 'connected',
      stats: {
        users: userCount,
        transactions: transactionCount,
        obligations: obligationCount,
        insights: insightCount,
      },
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    res.status(500).json({
      status: 'error',
      message: error?.message || 'Database connection error',
    });
  }
});

import { GmailWatcher } from './ingestion/gmailWatcher';

let server: any = null;

if (require.main === module) {
  server = app.listen(PORT, () => {
    console.log(`🚀 Financial Agent API running on http://localhost:${PORT}`);
    // Start automated transaction email watcher (every 30 seconds)
    GmailWatcher.startWatcher(30000);
  });
}

export { app, server };
export default app;
