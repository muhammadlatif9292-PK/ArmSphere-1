import { Router, Request, Response, NextFunction } from "express";
import swaggerUi from "swagger-ui-express";
import swaggerJSDoc from "swagger-jsdoc";
import { openapiDefinition } from "../config/openapi/index.js";

export const docsRouter = Router();

// Configure swagger-jsdoc
const swaggerOptions: swaggerJSDoc.Options = {
  swaggerDefinition: openapiDefinition as any,
  apis: ["./src/routes/*.ts", "./src/routes/*.js"], // In case developers write annotations in route files
};

const swaggerSpec = swaggerJSDoc(swaggerOptions);

/**
 * GET /api/v1/openapi.json
 * Exposes the full validated OpenAPI 3.1 specification for download.
 */
docsRouter.get("/openapi.json", (req: Request, res: Response) => {
  res.setHeader("Content-Type", "application/json");
  res.status(200).json(swaggerSpec);
});

// Custom CSS for a professional, eye-safe Dark Slate Theme
const darkSlateCss = `
  body { background-color: #0b0f19 !important; color: #f1f5f9 !important; font-family: 'Inter', sans-serif !important; }
  .swagger-ui { background-color: #0b0f19 !important; filter: invert(0) !important; }
  .swagger-ui .topbar { display: none !important; } /* Hide default topbar */
  .swagger-ui .info .title { color: #f8fafc !important; font-size: 2.2rem !important; font-weight: 700 !important; tracking: -0.05em !important; }
  .swagger-ui .info p, .swagger-ui .info li, .swagger-ui .info a { color: #94a3b8 !important; line-height: 1.6 !important; }
  .swagger-ui .info a { color: #38bdf8 !important; text-decoration: none !important; }
  .swagger-ui .info a:hover { text-decoration: underline !important; }
  .swagger-ui .scheme-container { background-color: #111827 !important; border: 1px solid #1f2937 !important; border-radius: 12px !important; box-shadow: none !important; margin: 20px 0 !important; padding: 20px !important; }
  .swagger-ui select { background-color: #1f2937 !important; color: #f1f5f9 !important; border: 1px solid #374151 !important; border-radius: 6px !important; }
  .swagger-ui select:focus { border-color: #38bdf8 !important; outline: none !important; }
  .swagger-ui .opblock { border-radius: 10px !important; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -1px rgba(0,0,0,0.06) !important; background-color: #111827 !important; border: 1px solid #1f2937 !important; }
  .swagger-ui .opblock .opblock-summary { border-bottom: 1px solid rgba(255,255,255,0.04) !important; padding: 12px 20px !important; }
  .swagger-ui .opblock .opblock-summary-title { color: #f1f5f9 !important; font-weight: 600 !important; }
  .swagger-ui .opblock .opblock-summary-description { color: #94a3b8 !important; }
  .swagger-ui .opblock-tag { border-bottom: 1px solid #1f2937 !important; color: #f8fafc !important; font-size: 1.4rem !important; padding: 15px 0 10px 0 !important; }
  .swagger-ui .opblock-tag small { color: #6b7280 !important; }
  .swagger-ui .opblock .opblock-section-header { background: #1f2937 !important; border-bottom: 1px solid #374151 !important; color: #f1f5f9 !important; }
  .swagger-ui .opblock .opblock-section-header h4 { color: #f1f5f9 !important; }
  .swagger-ui .tabli button { color: #94a3b8 !important; font-weight: 600 !important; }
  .swagger-ui .tabli.active button { color: #38bdf8 !important; border-bottom-color: #38bdf8 !important; }
  .swagger-ui .response-col_status { color: #38bdf8 !important; font-weight: 700 !important; }
  .swagger-ui table thead tr td, .swagger-ui table thead tr th { color: #94a3b8 !important; border-bottom: 1px solid #1f2937 !important; font-weight: 600 !important; }
  .swagger-ui .parameter__name { color: #38bdf8 !important; font-family: monospace !important; font-weight: 600 !important; }
  .swagger-ui .parameter__type { color: #64748b !important; font-family: monospace !important; }
  .swagger-ui input[type=text] { background-color: #111827 !important; color: #f1f5f9 !important; border: 1px solid #374151 !important; border-radius: 6px !important; padding: 8px 12px !important; }
  .swagger-ui input[type=text]:focus { border-color: #38bdf8 !important; outline: none !important; }
  .swagger-ui .btn { background-color: #1f2937 !important; color: #f1f5f9 !important; border: 1px solid #374151 !important; border-radius: 6px !important; transition: all 0.2s ease !important; }
  .swagger-ui .btn:hover { background-color: #374151 !important; }
  .swagger-ui .btn.authorize { background-color: #0e9f6e !important; border-color: #0e9f6e !important; color: #ffffff !important; }
  .swagger-ui .btn.authorize:hover { background-color: #057a55 !important; }
  .swagger-ui .btn.execute { background-color: #0284c7 !important; border-color: #0284c7 !important; color: #ffffff !important; font-weight: 600 !important; }
  .swagger-ui .btn.execute:hover { background-color: #0369a1 !important; }
  .swagger-ui .model-box { background: #111827 !important; border: 1px solid #1f2937 !important; border-radius: 8px !important; padding: 10px !important; }
  .swagger-ui .model { color: #cbd5e1 !important; }
  .swagger-ui .model-title { color: #f1f5f9 !important; }
  .swagger-ui .prop-type { color: #f43f5e !important; }
  .swagger-ui .prop-format { color: #64748b !important; }
  .swagger-ui .servers-title { color: #94a3b8 !important; }
  /* Custom beautiful badge styling */
  .swagger-ui .opblock.opblock-get { border-color: #0369a1 !important; background: rgba(3, 105, 161, 0.05) !important; }
  .swagger-ui .opblock.opblock-get .opblock-summary-method { background: #0284c7 !important; border-radius: 4px !important; }
  .swagger-ui .opblock.opblock-post { border-color: #065f46 !important; background: rgba(6, 95, 70, 0.05) !important; }
  .swagger-ui .opblock.opblock-post .opblock-summary-method { background: #059669 !important; border-radius: 4px !important; }
  .swagger-ui .opblock.opblock-put { border-color: #854d0e !important; background: rgba(133, 77, 14, 0.05) !important; }
  .swagger-ui .opblock.opblock-put .opblock-summary-method { background: #ca8a04 !important; border-radius: 4px !important; }
  .swagger-ui .opblock.opblock-delete { border-color: #991b1b !important; background: rgba(153, 27, 27, 0.05) !important; }
  .swagger-ui .opblock.opblock-delete .opblock-summary-method { background: #dc2626 !important; border-radius: 4px !important; }
  .swagger-ui .opblock.opblock-patch { border-color: #5b21b6 !important; background: rgba(91, 33, 182, 0.05) !important; }
  .swagger-ui .opblock.opblock-patch .opblock-summary-method { background: #7c3aed !important; border-radius: 4px !important; }
`;

// Setup options for swagger-ui
const swaggerUiOptions = {
  customCss: darkSlateCss,
  customSiteTitle: "ArmSphere Professional API Documentation",
  swaggerOptions: {
    filter: true, // Enables client-side path filtering (Search)
    displayRequestDuration: true,
    persistAuthorization: true,
  },
};

// Swagger UI bootstraps via an inline script and inline styles. Relax CSP for
// these docs routes ONLY — the application-wide policy stays strict.
// NOTE: registered BEFORE the swagger handlers so Express actually applies it.
docsRouter.use("/docs", (req: Request, res: Response, next: NextFunction) => {
  res.setHeader(
    "Content-Security-Policy",
    [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data:",
      "connect-src 'self'",
      "font-src 'self' data:",
      "frame-ancestors 'none'",
      "object-src 'none'",
      "base-uri 'self'"
    ].join("; ")
  );
  next();
});

// Bind Swagger UI routes
docsRouter.use("/docs", swaggerUi.serve);
docsRouter.get("/docs", swaggerUi.setup(swaggerSpec, swaggerUiOptions));

export default docsRouter;
