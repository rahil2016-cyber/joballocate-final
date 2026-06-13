import { readFile } from "node:fs/promises";

const LOGO_PATH =
  "C:/Users/User/.cursor/projects/c-Users-User-Desktop-mobile-7-backend/assets/c__Users_User_AppData_Roaming_Cursor_User_workspaceStorage_df2c1af8bf5920e84614e0237d357482_images_WhatsApp_Image_2026-04-22_at_1.23.50_PM-d070045d-e9ea-483a-af5b-113d83acd63e.png";

export async function GET() {
  try {
    const buffer = await readFile(LOGO_PATH);
    return new Response(buffer, {
      headers: {
        "Content-Type": "image/png",
        "Cache-Control": "public, max-age=31536000, immutable",
      },
    });
  } catch {
    return new Response("Logo not found", { status: 404 });
  }
}
