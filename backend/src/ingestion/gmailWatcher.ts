import prisma from '../db/prisma';
import { pollGmailForUser } from './gmailClient';
import { parseGmailMessage } from './gmailParser';
import { PipelineCoordinator } from '../pipeline/pipelineCoordinator';
import { DEMO_USER_ID } from '../constants';

export class GmailWatcher {
  private static isRunning = false;
  private static timer: NodeJS.Timeout | null = null;
  private static processedMessageIds = new Set<string>();

  /**
   * Start background polling watcher to automatically ingest and parse transaction emails
   * Runs every intervalMs (default: 30 seconds)
   */
  public static startWatcher(intervalMs: number = 30000) {
    if (this.isRunning) {
      console.log('📬 GmailWatcher already running.');
      return;
    }

    this.isRunning = true;
    console.log(`📬 [GmailWatcher] Started continuous transaction email parser (interval: ${intervalMs / 1000}s)`);

    // Run immediate scan
    this.syncUserInbox(DEMO_USER_ID).catch(err => console.error('Initial Gmail sync error:', err));

    // Schedule recurring background interval
    this.timer = setInterval(async () => {
      try {
        await this.syncUserInbox(DEMO_USER_ID);
      } catch (err) {
        console.error('Error during scheduled Gmail sync:', err);
      }
    }, intervalMs);
  }

  /**
   * Stop background polling watcher
   */
  public static stopWatcher() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
    this.isRunning = false;
    console.log('📬 [GmailWatcher] Stopped continuous transaction email parser.');
  }

  /**
   * Synchronize and parse all new financial emails for a given user
   */
  public static async syncUserInbox(userId: string = DEMO_USER_ID) {
    const rawEmails = await pollGmailForUser(userId, 10);
    const parsedEvents = [];

    for (const rawEmail of rawEmails) {
      // Avoid processing the exact same email multiple times in memory
      if (this.processedMessageIds.has(rawEmail.id)) {
        continue;
      }

      const event = parseGmailMessage(rawEmail, userId);
      if (event) {
        this.processedMessageIds.add(rawEmail.id);
        const pipelineResult = await PipelineCoordinator.processEvent(event);
        parsedEvents.push({
          messageId: rawEmail.id,
          subject: rawEmail.subject,
          sender: rawEmail.sender,
          merchant: event.merchant,
          amount: event.amount,
          type: event.type,
          dedup: pipelineResult.dedupResult,
          insightCreated: pipelineResult.insightCreated,
        });
      }
    }

    return {
      syncedCount: rawEmails.length,
      parsedTransactionsCount: parsedEvents.length,
      transactions: parsedEvents,
      timestamp: new Date().toISOString(),
    };
  }
}
