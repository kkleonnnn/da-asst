#!/usr/bin/env python3
# 本地 OCR：图片型 PDF → 逐页渲染 → PaddleOCR 识别 → 纯文本。
# 两种用法：
#   单文件(打印到 stdout，测试用)： .venv-ocr/bin/python scripts/ocr_pdf.py <某.pdf>
#   批量(写 <outdir>/<base>.txt，跳过已存在)： .venv-ocr/bin/python scripts/ocr_pdf.py --out <outdir> <pdf...>
# 依赖：.venv-ocr 的 paddleocr/paddlepaddle + 系统 poppler(pdftoppm)。
# 注意：输出文本是原始来源内容(含指纹)，只能留本地(inbox/_ocr/)，绝不入库；
#       交给 LLM 消化时再改写脱敏。
import sys, os, subprocess, tempfile, glob, time

CPU = os.cpu_count() or 8
os.environ.setdefault("OMP_NUM_THREADS", str(CPU))
os.environ.setdefault("FLAGS_use_mkldnn", "1")
DPI = int(os.environ.get("OCR_DPI", "120"))

def make_ocr():
    from paddleocr import PaddleOCR
    common = dict(lang="ch",
                  use_doc_orientation_classify=False,
                  use_doc_unwarping=False,
                  use_textline_orientation=False)
    det = os.environ.get("OCR_DET_MODEL")  # 如 PP-OCRv5_mobile_det
    rec = os.environ.get("OCR_REC_MODEL")  # 如 PP-OCRv5_mobile_rec
    if det:
        common["text_detection_model_name"] = det
    if rec:
        common["text_recognition_model_name"] = rec
    threads = int(os.environ.get("OCR_THREADS", str(CPU)))
    for extra in (dict(cpu_threads=threads, enable_mkldnn=True), dict(cpu_threads=threads), {}):
        try:
            return PaddleOCR(**common, **extra)
        except Exception:
            continue
    return PaddleOCR(lang="ch")

def page_texts(ocr, img):
    try:
        res = ocr.predict(input=img)
    except TypeError:
        res = ocr.predict(img)
    out = []
    for r in res:
        rt = None
        try:
            rt = r["rec_texts"]
        except Exception:
            j = getattr(r, "json", None)
            if isinstance(j, dict):
                rt = j.get("res", {}).get("rec_texts") or j.get("rec_texts")
        if rt:
            out.extend(rt)
    return out

def ocr_pdf(ocr, pdf):
    texts = []
    with tempfile.TemporaryDirectory() as td:
        base = os.path.join(td, "pg")
        subprocess.run(["pdftoppm", "-png", "-r", str(DPI), pdf, base],
                       check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        for pg in sorted(glob.glob(base + "*.png")):
            texts.append("\n".join(page_texts(ocr, pg)))
    return "\n\n".join(texts).strip() + "\n"

def main():
    args = sys.argv[1:]
    if args and args[0] == "--out":
        outdir = args[1]; pdfs = args[2:]
        os.makedirs(outdir, exist_ok=True)
        ocr = make_ocr()
        for i, pdf in enumerate(pdfs, 1):
            base = os.path.splitext(os.path.basename(pdf))[0]
            dst = os.path.join(outdir, base + ".txt")
            if os.path.exists(dst):
                print(f"[{i}/{len(pdfs)}] skip(已存在) {base}", file=sys.stderr); continue
            t = time.time()
            try:
                txt = ocr_pdf(ocr, pdf)
                with open(dst, "w") as f:
                    f.write(txt)
                print(f"[{i}/{len(pdfs)}] ok {len(txt)}字 {time.time()-t:.0f}s {base}", file=sys.stderr)
            except Exception as e:
                print(f"[{i}/{len(pdfs)}] FAIL {base}: {e}", file=sys.stderr)
    else:
        ocr = make_ocr()
        sys.stdout.write(ocr_pdf(ocr, args[0]))

if __name__ == "__main__":
    main()
