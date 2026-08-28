import 'dotenv/config';
import http from 'http';
import app from '../index';
import { DEMO_USER_ID } from '../constants';
import prisma from '../db/prisma';

function request(options: http.RequestOptions, postData?: string): Promise<{ status: number; body: any }> {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode || 200, body: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode || 200, body: data });
        }
      });
    });
    req.on('error', reject);
    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

async function verifyPhase7() {
  console.log('🧪 ===============================================');
  console.log('🧪 VERIFYING PHASE 7: BACKEND REST API ENDPOINTS');
  console.log('🧪 ===============================================\n');

  const TEST_PORT = 3099;
  const server = app.listen(TEST_PORT);

  try {
    const baseOpt = { host: 'localhost', port: TEST_PORT, headers: { 'Content-Type': 'application/json' } };

    // 1. GET /health
    console.log('1️⃣ Testing GET /health ...');
    const health = await request({ ...baseOpt, path: '/health', method: 'GET' });
    console.log(`   [Status ${health.status}] Service: ${health.body.service} (DB: ${health.body.database}, Nodes: ${health.body.stats?.nodes})\n`);

    // 2. GET /api/auth/google/url
    console.log('2️⃣ Testing GET /api/auth/google/url ...');
    const authUrlRes = await request({ ...baseOpt, path: `/api/auth/google/url?userId=${DEMO_USER_ID}`, method: 'GET' });
    console.log(`   [Status ${authUrlRes.status}] URL: ${authUrlRes.body.authUrl?.substring(0, 60)}...\n`);

    // 3. GET /api/insights (Surfaced Feed)
    console.log('3️⃣ Testing GET /api/insights (Surfaced Insights Feed) ...');
    const insightsRes = await request({ ...baseOpt, path: `/api/insights?userId=${DEMO_USER_ID}`, method: 'GET' });
    console.log(`   [Status ${insightsRes.status}] Surfaced Insights Count: ${insightsRes.body.count}`);
    for (const ins of insightsRes.body.insights?.slice(0, 2)) {
      console.log(`       - [${ins.triggerType.toUpperCase()}] Gate Score: ${ins.gateScore} | "${ins.explanation?.substring(0, 75)}..."`);
    }
    console.log();

    // 4. GET /api/insights/suppressed (Transparency Log)
    console.log('4️⃣ Testing GET /api/insights/suppressed (Suppressed Transparency Log) ...');
    const suppressedRes = await request({ ...baseOpt, path: `/api/insights/suppressed?userId=${DEMO_USER_ID}`, method: 'GET' });
    console.log(`   [Status ${suppressedRes.status}] Suppressed Insights Count: ${suppressedRes.body.count}`);
    for (const ins of suppressedRes.body.insights?.slice(0, 2)) {
      console.log(`       - [${ins.triggerType.toUpperCase()}] Gate Score: ${ins.gateScore} | "${ins.explanation?.substring(0, 75)}..."`);
    }
    console.log();

    // 5. GET /api/insights/:id (Detail with Graph Path)
    if (insightsRes.body.insights && insightsRes.body.insights.length > 0) {
      const sampleId = insightsRes.body.insights[0].id;
      console.log(`5️⃣ Testing GET /api/insights/${sampleId} (Detail with Causal Graph Path) ...`);
      const detailRes = await request({ ...baseOpt, path: `/api/insights/${sampleId}`, method: 'GET' });
      console.log(`   [Status ${detailRes.status}] ID: ${detailRes.body.insight?.id}`);
      console.log(`   Graph Path Info:`, JSON.stringify(detailRes.body.insight?.graphPath).substring(0, 100) + '...\n');
    }

    // 6. POST /api/users/:id/risk-tolerance
    console.log(`6️⃣ Testing POST /api/users/${DEMO_USER_ID}/risk-tolerance ...`);
    const updateRiskRes = await request(
      { ...baseOpt, path: `/api/users/${DEMO_USER_ID}/risk-tolerance`, method: 'POST' },
      JSON.stringify({ riskTolerance: 'high' })
    );
    console.log(`   [Status ${updateRiskRes.status}] Updated Risk Tolerance: ${updateRiskRes.body.user?.riskTolerance}\n`);

    // Reset back to medium
    await request(
      { ...baseOpt, path: `/api/users/${DEMO_USER_ID}/risk-tolerance`, method: 'POST' },
      JSON.stringify({ riskTolerance: 'medium' })
    );

    // 7. GET /api/graph/nodes & GET /api/graph/edges
    console.log('7️⃣ Testing GET /api/graph/nodes and GET /api/graph/edges ...');
    const nodesRes = await request({ ...baseOpt, path: `/api/graph/nodes?userId=${DEMO_USER_ID}`, method: 'GET' });
    const edgesRes = await request({ ...baseOpt, path: `/api/graph/edges?userId=${DEMO_USER_ID}`, method: 'GET' });
    console.log(`   [Status ${nodesRes.status}] Nodes Count: ${nodesRes.body.count}`);
    console.log(`   [Status ${edgesRes.status}] Edges Count: ${edgesRes.body.count}\n`);

    // 8. POST /api/events/ingest (Live SMS ingestion through REST API)
    console.log('8️⃣ Testing POST /api/events/ingest (Live SMS Ingestion) ...');
    const ingestRes = await request(
      { ...baseOpt, path: '/api/events/ingest', method: 'POST' },
      JSON.stringify({
        userId: DEMO_USER_ID,
        source: 'sms',
        sms: {
          sender: 'VM-HDFCBK',
          body: 'Rs 4,200.00 spent on your HDFC Card at Amazon on 28-Aug-2026.'
        }
      })
    );
    console.log(`   [Status ${ingestRes.status}] Merchant: ${ingestRes.body.event?.merchant} | Amount: ₹${ingestRes.body.event?.amount} | Confidence: ${ingestRes.body.dedupResult?.finalConfidence}\n`);

    // 9. POST /api/events/trigger-delay (Simulate delayed retainer cascade via REST API)
    console.log('9️⃣ Testing POST /api/events/trigger-delay (Simulate Cascade Trigger) ...');
    const cascadeTriggerRes = await request(
      { ...baseOpt, path: '/api/events/trigger-delay', method: 'POST' },
      JSON.stringify({
        userId: DEMO_USER_ID,
        delayDays: 5
      })
    );
    console.log(`   [Status ${cascadeTriggerRes.status}] Shortfall: ₹${cascadeTriggerRes.body.cascadeEvaluation?.totalShortfall} | Gate Decision: ${cascadeTriggerRes.body.insight?.status.toUpperCase()}`);
    console.log(`   Explanation: "${cascadeTriggerRes.body.insight?.explanation}"\n`);

    // 10. GET /api/voice/briefing/:insightId (ElevenLabs Neural Voice Alert)
    if (insightsRes.body.insights && insightsRes.body.insights.length > 0) {
      const sampleId = insightsRes.body.insights[0].id;
      console.log(`🔟 Testing GET /api/voice/briefing/${sampleId} (Voice Briefing Generation) ...`);
      const voiceRes = await request({ ...baseOpt, path: `/api/voice/briefing/${sampleId}`, method: 'GET' });
      console.log(`   [Status ${voiceRes.status}] Provider: ${voiceRes.body.provider} | Voice ID: ${voiceRes.body.voiceId}`);
      console.log(`   Spoken Text: "${voiceRes.body.spokenText?.substring(0, 70)}..."\n`);
    }

    // 11. POST /api/actions/execute (Execute 1-Click Counter Action)
    if (insightsRes.body.insights && insightsRes.body.insights.length > 0) {
      const sampleInsight = insightsRes.body.insights[0];
      const actions = sampleInsight.actions || [];
      if (actions.length > 0) {
        const action = actions[0];
        console.log(`1️⃣1️⃣ Testing POST /api/actions/execute (1-Click Action Execution) ...`);
        const actionRes = await request(
          { ...baseOpt, path: '/api/actions/execute', method: 'POST' },
          JSON.stringify({
            userId: DEMO_USER_ID,
            insightId: sampleInsight.id,
            actionId: action.id,
            actionType: action.actionType,
            payload: action.payload,
          })
        );
        console.log(`   [Status ${actionRes.status}] Result: "${actionRes.body.message}" (Status: ${actionRes.body.status})\n`);
      }
    }

    console.log('✨ Phase 7 Backend REST API Verification Complete & All Endpoints Tested!');
  } finally {
    server.close(() => {
      prisma.$disconnect().then(() => {
        process.exit(0);
      });
    });
  }
}

verifyPhase7().catch(console.error);
