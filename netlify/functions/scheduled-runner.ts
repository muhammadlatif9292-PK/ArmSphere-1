import { runDueScheduledJobs } from "../../apps/api/src/services/scheduledJobs.js";

export const handler = async (event: any, context: any) => {
  try {
    const result = await runDueScheduledJobs();
    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        success: true,
        message: "Scheduled jobs execution completed successfully",
        data: result,
      }),
    };
  } catch (error: any) {
    return {
      statusCode: 500,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        success: false,
        error: error?.message || "Internal server error running scheduled jobs",
      }),
    };
  }
};
