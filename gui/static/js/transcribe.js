console.log("[transcribe.js] loaded");
(function () {
  const form = document.getElementById("transcribe-form");
  if (!form) { console.warn("[transcribe] form not found"); return; }

  const fileRadio = document.getElementById("source-file") || form.querySelector('input[name="source"][value="file"]');
  const urlRadio  = document.getElementById("source-url")  || form.querySelector('input[name="source"][value="url"]');
  const fileGroup = document.getElementById("file-group");
  const urlGroup  = document.getElementById("url-group");
  const fileInput = document.getElementById("video-file");
  const urlInput  = document.getElementById("video-url");
  const progress  = document.getElementById("progress");
  const ppPara    = document.getElementById("pp-paraphrase");
  const out       = document.querySelector("#transcript-output, #output, pre");

  function show(el, on) { if (el) el.style.display = on ? "" : "none"; }
  function enable(el, on) { if (el) el.disabled = !on; }

  function updateMode() {
    const useFile = !!(fileRadio && fileRadio.checked);
    show(fileGroup, useFile);
    show(urlGroup, !useFile);
    enable(fileInput, useFile);
    enable(urlInput, !useFile);
    console.log("[transcribe] mode:", useFile ? "file" : "url");
  }

  if (fileRadio) fileRadio.addEventListener("change", updateMode);
  if (urlRadio)  urlRadio.addEventListener("change", updateMode);
  updateMode();

  form.addEventListener("submit", async (e) => {
    e.preventDefault();
    if (out) out.textContent = "";
    if (progress) progress.style.display = "";

    try {
      const fd = new FormData();
      const usingFile = fileRadio && fileRadio.checked;

      if (usingFile) {
        if (!fileInput || !fileInput.files || !fileInput.files[0]) {
          throw new Error("Please choose a video file.");
        }
        fd.append("file", fileInput.files[0]);
      } else {
        const url = (urlInput && urlInput.value || "").trim();
        if (!url) throw new Error("Please paste a video URL.");
        if (!/^https?:\/\//i.test(url)) throw new Error("URL must start with http:// or https://");
        fd.append("video_url", url);
      }

      const endpoint = usingFile ? "/transcribe" : "/transcribe_url";
      if (ppPara && ppPara.checked) fd.append("paraphrase", "1");
      const res = await fetch(endpoint, { method: "POST", body: fd });
      const raw = await res.text();
      console.log("[transcribe] status", res.status, "endpoint", endpoint, "raw:", raw);

      if (!res.ok) throw new Error(`Server error ${res.status}: ${raw || res.statusText}`);

      let data; try { data = JSON.parse(raw); } catch { data = { raw }; }
      const t = (data && (data.transcript || data.text || data.raw)) || (typeof raw === "string" ? raw : JSON.stringify(data||{}, null, 2));
      printOut(t);
    } catch (err) {
      if (out) out.textContent = `Error: ${err.message || err}`;
    } finally {
      if (progress) progress.style.display = "none";
    }
  });
})();
