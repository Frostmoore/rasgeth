// @vitest-environment jsdom
// The paged preview when LibreOffice cannot be downloaded (3.12.8): the cause in plain words from
// the job's code, the server's details below, and «Riprova». Before, only «fetch failed».
import { cleanup, render } from "@testing-library/preact";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { lang } from "../src/i18n.js";

const failed = {
  id: "job_1",
  kind: "preview_file",
  vars: {},
  state: "failed",
  steps: [],
  error: {
    code: "libreoffice_download",
    message:
      "Could not download LibreOffice: appimages.libreitalia.org: CERT_HAS_EXPIRED; download.documentfoundation.org answered 503",
  },
};

vi.mock("../src/state.js", async (orig) => ({
  ...(await orig<typeof import("../src/state.js")>()),
  getApi: () =>
    new Proxy(
      {},
      {
        get: (_t, name) => {
          if (name === "startFilePreview")
            return () => Promise.resolve({ ready: false, job: { ...failed, state: "running" } });
          if (name === "job") return () => Promise.resolve(failed);
          if (name === "fileFormats")
            return () =>
              Promise.resolve({
                programs: [{ id: "libreoffice", here: false, canDownload: true }],
              });
          return () => Promise.resolve([]);
        },
      },
    ),
}));

const { PagedView } = await import("../src/components/viewers/OpenCopy.js");

beforeEach(() => {
  lang.value = "it";
});
afterEach(() => cleanup());

describe("the paged preview when LibreOffice cannot come", () => {
  it("says why in plain words, with the details for whoever helps", async () => {
    const { findByText, getByText } = render(
      <PagedView scope="project:p" path="Preventivo.docx" name="Preventivo.docx" url="/f" />,
    );
    await findByText("Non sono riuscito a preparare l'anteprima impaginata");
    getByText(/Non sono riuscito a scaricare LibreOffice/);
    getByText(/CERT_HAS_EXPIRED/);
    getByText("Riprova");
  });
});
