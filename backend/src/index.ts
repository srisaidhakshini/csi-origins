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

// Health check
app.get('/health', async (_req, res) => {
  try {
    const userCount = await prisma.user.count();
    const nodeCount = await prisma.node.count();
    const insightCount = await prisma.insight.count();

    res.json({
      status: 'ok',
      service: 'Autonomous Financial Management Agent API',
      database: 'connected',
      stats: {
        users: userCount,
        nodes: nodeCount,
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
