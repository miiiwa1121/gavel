import React, { useState, useRef, useEffect, useCallback } from "react";
import {
  Home, LayoutGrid, Camera as CameraIcon, Wallet as WalletIcon, User,
  Search, ArrowLeft, ChevronRight, Check, X, Clock, Circle, Square,
  RotateCcw, CheckCircle2, XCircle, AlertCircle, Video, Image as ImageIcon,
  Utensils, ShoppingCart, Heart, MapPin, Calendar, Users, TrendingUp,
  Download, Play
} from "lucide-react";

// ---------- constants & sample data ----------

const CATEGORIES = ["すべて", "料理", "歩行", "買い物", "介護", "生活風景"];

const CATEGORY_ICON = {
  "料理": Utensils,
  "歩行": MapPin,
  "買い物": ShoppingCart,
  "介護": Heart,
  "生活風景": Home,
};

const ACCENTS = {
  indigo: { tint: "var(--indigo-tint)", fg: "var(--indigo)" },
  sage: { tint: "var(--sage-tint)", fg: "var(--sage)" },
  momiji: { tint: "var(--momiji-tint)", fg: "var(--momiji)" },
};

const INITIAL_PROJECTS = [
  {
    id: "p1", title: "和食の調理動画", category: "料理", companyName: "FoodTech株式会社",
    dataType: "video", reward: 800, recruitCount: 50, participantCount: 32,
    deadline: "2026-08-15",
    requirements: { minWidth: 1280, minHeight: 720, minDurationSec: 8, maxDurationSec: 120 },
    conditions: ["キッチンでの調理風景を撮影してください", "包丁・鍋など調理器具が映るように", "顔が映らないよう配慮してください"],
    accent: "indigo",
  },
  {
    id: "p2", title: "街歩き・歩行動画", category: "歩行", companyName: "Nexus Robotics",
    dataType: "video", reward: 500, recruitCount: 100, participantCount: 67,
    deadline: "2026-07-31",
    requirements: { minWidth: 1280, minHeight: 720, minDurationSec: 6, maxDurationSec: 60 },
    conditions: ["屋外の歩道を歩く様子を三人称視点で撮影", "1人以上の歩行者が映っていること", "私有地では撮影しないでください"],
    accent: "sage",
  },
  {
    id: "p3", title: "スーパーでの買い物風景", category: "買い物", companyName: "RetailAI Inc.",
    dataType: "video", reward: 600, recruitCount: 80, participantCount: 41,
    deadline: "2026-08-05",
    requirements: { minWidth: 1280, minHeight: 720, minDurationSec: 6, maxDurationSec: 90 },
    conditions: ["カゴに商品を入れる動作を撮影", "店舗の許可がある場所でのみ撮影してください"],
    accent: "momiji",
  },
  {
    id: "p4", title: "介護施設の生活風景（写真）", category: "介護", companyName: "CareLife Robotics",
    dataType: "photo", reward: 400, recruitCount: 40, participantCount: 9,
    deadline: "2026-08-20",
    requirements: { minWidth: 960, minHeight: 540 },
    conditions: ["施設内の共用スペースの様子を撮影", "個人が特定できる顔の写り込みはNGです", "施設の許可を得てから撮影してください"],
    accent: "indigo",
  },
  {
    id: "p5", title: "日本の生活風景スナップ", category: "生活風景", companyName: "Global Vision Labs",
    dataType: "photo", reward: 300, recruitCount: 200, participantCount: 118,
    deadline: "2026-09-01",
    requirements: { minWidth: 960, minHeight: 540 },
    conditions: ["日常のワンシーンを撮影（玄関・洗濯物・食卓など）", "生活感のある自然な構図でお願いします"],
    accent: "sage",
  },
];

const SHARPNESS_THRESHOLD = 18;

// ---------- image processing helpers ----------

function computeSharpness(source, srcW, srcH, crop = { x: 0, y: 0, w: 1, h: 1 }) {
  if (!srcW || !srcH) return 0;
  const cw = Math.max(2, Math.round(srcW * crop.w));
  const ch = Math.max(2, Math.round(srcH * crop.h));
  const cx = Math.round(srcW * crop.x);
  const cy = Math.round(srcH * crop.y);
  const targetW = 140;
  const scale = targetW / cw;
  const targetH = Math.max(2, Math.round(ch * scale));
  const canvas = document.createElement("canvas");
  canvas.width = targetW;
  canvas.height = targetH;
  const ctx = canvas.getContext("2d", { willReadFrequently: true });
  try {
    ctx.drawImage(source, cx, cy, cw, ch, 0, 0, targetW, targetH);
  } catch (e) {
    return 0;
  }
  let data;
  try {
    data = ctx.getImageData(0, 0, targetW, targetH).data;
  } catch (e) {
    return 0;
  }
  const gray = new Float32Array(targetW * targetH);
  for (let i = 0; i < targetW * targetH; i++) {
    gray[i] = 0.299 * data[i * 4] + 0.587 * data[i * 4 + 1] + 0.114 * data[i * 4 + 2];
  }
  let sum = 0, sumSq = 0, count = 0;
  for (let y = 1; y < targetH - 1; y++) {
    for (let x = 1; x < targetW - 1; x++) {
      const idx = y * targetW + x;
      const lap = gray[idx - 1] + gray[idx + 1] + gray[idx - targetW] + gray[idx + targetW] - 4 * gray[idx];
      sum += lap;
      sumSq += lap * lap;
      count++;
    }
  }
  const mean = sum / count;
  const variance = sumSq / count - mean * mean;
  return Math.sqrt(Math.max(0, variance));
}

function formatYen(n) {
  return "¥" + Number(n || 0).toLocaleString("ja-JP");
}

function daysLeft(dateStr) {
  const diff = Math.ceil((new Date(dateStr + "T23:59:59") - new Date()) / 86400000);
  return diff;
}

function nowStr() {
  const d = new Date();
  return `${d.getMonth() + 1}/${d.getDate()} ${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

// ---------- small shared UI pieces ----------

function AppHeader({ title, onBack }) {
  return (
    <div className="dm-header">
      {onBack ? (
        <button className="dm-icon-btn" onClick={onBack} aria-label="戻る">
          <ArrowLeft size={20} />
        </button>
      ) : <div style={{ width: 36 }} />}
      <div className="dm-header-title">{title}</div>
      <div style={{ width: 36 }} />
    </div>
  );
}

function ProgressBar({ value, max }) {
  const pct = Math.min(100, Math.round((value / max) * 100));
  return (
    <div className="dm-progress">
      <div className="dm-progress-fill" style={{ width: pct + "%" }} />
    </div>
  );
}

function BottomNav({ screen, go }) {
  const items = [
    { key: "home", label: "ホーム", icon: Home },
    { key: "projects", label: "案件", icon: LayoutGrid },
    { key: "camera-entry", label: "撮影", icon: CameraIcon, isCenter: true },
    { key: "wallet", label: "報酬", icon: WalletIcon },
    { key: "mypage", label: "マイページ", icon: User },
  ];
  return (
    <div className="dm-bottomnav">
      {items.map((it) => {
        const Icon = it.icon;
        const active = screen === it.key || (it.key === "projects" && screen === "detail");
        if (it.isCenter) {
          return (
            <button key={it.key} className="dm-nav-center" onClick={() => go("projects")} aria-label="撮影する案件を選ぶ">
              <CameraIcon size={22} />
            </button>
          );
        }
        return (
          <button key={it.key} className={"dm-nav-item" + (active ? " active" : "")} onClick={() => go(it.key)}>
            <Icon size={20} />
            <span>{it.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ---------- screens ----------

function HomeScreen({ projects, wallet, go, openProject }) {
  const recommended = projects.slice(0, 4);
  return (
    <div className="dm-content">
      <div className="dm-greeting">
        <div className="dm-eyebrow">おかえりなさい</div>
        <div className="dm-greeting-title">今日も撮って、貢献しよう</div>
      </div>

      <button className="dm-wallet-card" onClick={() => go("wallet")}>
        <div>
          <div className="dm-wallet-label">受取可能残高</div>
          <div className="dm-wallet-amount">{formatYen(wallet.balance)}</div>
          {wallet.pending > 0 && (
            <div className="dm-wallet-pending">審査中 {formatYen(wallet.pending)}</div>
          )}
        </div>
        <ChevronRight size={20} color="var(--paper)" />
      </button>

      <div className="dm-section-head">
        <div className="dm-section-title">カテゴリーから探す</div>
      </div>
      <div className="dm-chip-row">
        {CATEGORIES.filter((c) => c !== "すべて").map((c) => {
          const Icon = CATEGORY_ICON[c];
          return (
            <button key={c} className="dm-category-tile" onClick={() => go("projects", { category: c })}>
              <Icon size={18} color="var(--indigo)" />
              <span>{c}</span>
            </button>
          );
        })}
      </div>

      <div className="dm-section-head">
        <div className="dm-section-title">おすすめの案件</div>
        <button className="dm-link" onClick={() => go("projects")}>すべて見る</button>
      </div>
      <div className="dm-hscroll">
        {recommended.map((p) => (
          <button key={p.id} className="dm-reco-card" onClick={() => openProject(p.id)}>
            <div className="dm-reco-thumb" style={{ background: ACCENTS[p.accent].tint }}>
              {React.createElement(CATEGORY_ICON[p.category], { size: 28, color: ACCENTS[p.accent].fg })}
            </div>
            <div className="dm-reco-title">{p.title}</div>
            <div className="dm-reco-reward">{formatYen(p.reward)} / 件</div>
          </button>
        ))}
      </div>
    </div>
  );
}

function ProjectsScreen({ projects, filterCategory, setFilterCategory, openProject }) {
  const [query, setQuery] = useState("");
  const filtered = projects.filter((p) => {
    const matchCat = filterCategory === "すべて" || p.category === filterCategory;
    const matchQuery = (p.title + p.companyName).toLowerCase().includes(query.toLowerCase());
    return matchCat && matchQuery;
  });
  return (
    <div className="dm-content">
      <div className="dm-search">
        <Search size={16} color="var(--ink-soft)" />
        <input
          placeholder="案件名・企業名で検索"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>
      <div className="dm-chip-row scroll">
        {CATEGORIES.map((c) => (
          <button
            key={c}
            className={"dm-filter-chip" + (filterCategory === c ? " active" : "")}
            onClick={() => setFilterCategory(c)}
          >
            {c}
          </button>
        ))}
      </div>

      <div className="dm-list">
        {filtered.map((p) => {
          const left = p.recruitCount - p.participantCount;
          const closed = left <= 0;
          const dl = daysLeft(p.deadline);
          return (
            <button key={p.id} className="dm-project-card" onClick={() => openProject(p.id)}>
              <div className="dm-project-thumb" style={{ background: ACCENTS[p.accent].tint }}>
                {React.createElement(CATEGORY_ICON[p.category], { size: 26, color: ACCENTS[p.accent].fg })}
                <span className="dm-datatype-badge">
                  {p.dataType === "video" ? <Video size={11} /> : <ImageIcon size={11} />}
                  {p.dataType === "video" ? "動画" : "写真"}
                </span>
              </div>
              <div className="dm-project-body">
                <div className="dm-project-top">
                  <span className="dm-project-category">{p.category}</span>
                  {closed ? (
                    <span className="dm-badge-closed">募集終了</span>
                  ) : (
                    <span className="dm-badge-deadline">
                      <Clock size={11} /> あと{dl > 0 ? dl : 0}日
                    </span>
                  )}
                </div>
                <div className="dm-project-title">{p.title}</div>
                <div className="dm-project-company">{p.companyName}</div>
                <ProgressBar value={p.participantCount} max={p.recruitCount} />
                <div className="dm-project-bottom">
                  <span className="dm-project-participants">
                    <Users size={12} /> {p.participantCount}/{p.recruitCount}人
                  </span>
                  <span className="dm-project-reward">{formatYen(p.reward)}</span>
                </div>
              </div>
            </button>
          );
        })}
        {filtered.length === 0 && (
          <div className="dm-empty">条件に一致する案件が見つかりませんでした</div>
        )}
      </div>
    </div>
  );
}

function ProjectDetailScreen({ project, go, startShooting }) {
  if (!project) return null;
  const left = project.recruitCount - project.participantCount;
  const closed = left <= 0;
  const dl = daysLeft(project.deadline);
  return (
    <>
      <div className="dm-content no-pad">
        <div className="dm-detail-hero" style={{ background: ACCENTS[project.accent].tint }}>
          {React.createElement(CATEGORY_ICON[project.category], { size: 56, color: ACCENTS[project.accent].fg })}
        </div>
        <div className="dm-detail-body">
          <div className="dm-project-category">{project.category} ・ {project.companyName}</div>
          <div className="dm-detail-title">{project.title}</div>

          <div className="dm-detail-reward-row">
            <div>
              <div className="dm-detail-reward-label">投稿1件あたりの報酬</div>
              <div className="dm-detail-reward">{formatYen(project.reward)}</div>
            </div>
            <div className="dm-detail-meta">
              <div><Calendar size={13} /> 締切まであと{dl > 0 ? dl : 0}日</div>
              <div><Users size={13} /> {project.participantCount}/{project.recruitCount}人が参加中</div>
            </div>
          </div>
          <ProgressBar value={project.participantCount} max={project.recruitCount} />

          <div className="dm-detail-section">
            <div className="dm-detail-section-title">品質基準（AI自動チェック）</div>
            <ul className="dm-check-list">
              <li>解像度：{project.requirements.minWidth}×{project.requirements.minHeight} 以上</li>
              {project.dataType === "video" && (
                <li>撮影時間：{project.requirements.minDurationSec}〜{project.requirements.maxDurationSec}秒</li>
              )}
              <li>ブレ・ピントの自動判定に合格する必要があります</li>
            </ul>
          </div>

          <div className="dm-detail-section">
            <div className="dm-detail-section-title">撮影条件</div>
            <ul className="dm-check-list">
              {project.conditions.map((c, i) => <li key={i}>{c}</li>)}
            </ul>
          </div>
        </div>
      </div>
      <div className="dm-sticky-cta">
        <button
          className="dm-primary-btn"
          disabled={closed}
          onClick={() => startShooting(project)}
        >
          {closed ? "この案件は募集を終了しました" : `この案件で${project.dataType === "video" ? "撮影" : "撮影"}する`}
        </button>
      </div>
    </>
  );
}

function CameraScreen({ project, onCancel, onCaptured }) {
  const videoRef = useRef(null);
  const streamRef = useRef(null);
  const recorderRef = useRef(null);
  const chunksRef = useRef([]);
  const timerRef = useRef(null);
  const liveTimerRef = useRef(null);

  const [mode, setMode] = useState(project.dataType === "video" ? "video" : "photo");
  const [error, setError] = useState(null);
  const [isRecording, setIsRecording] = useState(false);
  const [seconds, setSeconds] = useState(0);
  const [liveSharpness, setLiveSharpness] = useState(0);
  const [processing, setProcessing] = useState(false);

  const stopStream = useCallback(() => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
    }
  }, []);

  const startCamera = useCallback(async () => {
    setError(null);
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: { ideal: "environment" }, width: { ideal: 1280 }, height: { ideal: 720 } },
        audio: mode === "video",
      });
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
      }
    } catch (e) {
      setError("カメラにアクセスできませんでした。ブラウザの権限設定でカメラへのアクセスを許可してください。");
    }
  }, [mode]);

  useEffect(() => {
    startCamera();
    return () => {
      stopStream();
      clearInterval(timerRef.current);
      clearInterval(liveTimerRef.current);
    };
    // eslint-disable-next-line
  }, [mode]);

  useEffect(() => {
    liveTimerRef.current = setInterval(() => {
      const v = videoRef.current;
      if (v && v.videoWidth) {
        const s = computeSharpness(v, v.videoWidth, v.videoHeight, { x: 0.25, y: 0.25, w: 0.5, h: 0.5 });
        setLiveSharpness(s);
      }
    }, 700);
    return () => clearInterval(liveTimerRef.current);
  }, []);

  function takePhoto() {
    const video = videoRef.current;
    if (!video || !video.videoWidth) return;
    const canvas = document.createElement("canvas");
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext("2d");
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    const url = canvas.toDataURL("image/jpeg", 0.9);
    const blurScore = computeSharpness(canvas, canvas.width, canvas.height, { x: 0, y: 0, w: 1, h: 1 });
    const focusScore = computeSharpness(canvas, canvas.width, canvas.height, { x: 0.25, y: 0.25, w: 0.5, h: 0.5 });
    stopStream();
    onCaptured({
      type: "photo",
      url,
      width: canvas.width,
      height: canvas.height,
      durationSec: null,
      blurScore,
      focusScore,
    });
  }

  function startRecording() {
    const stream = streamRef.current;
    if (!stream) return;
    chunksRef.current = [];
    let mimeType = "video/webm;codecs=vp8,opus";
    if (typeof MediaRecorder.isTypeSupported === "function" && !MediaRecorder.isTypeSupported(mimeType)) {
      mimeType = "video/webm";
    }
    let recorder;
    try {
      recorder = new MediaRecorder(stream, { mimeType });
    } catch (e) {
      recorder = new MediaRecorder(stream);
    }
    recorder.ondataavailable = (e) => {
      if (e.data && e.data.size > 0) chunksRef.current.push(e.data);
    };
    recorder.onstop = handleStop;
    recorder.start();
    recorderRef.current = recorder;
    setIsRecording(true);
    setSeconds(0);
    timerRef.current = setInterval(() => setSeconds((s) => s + 1), 1000);
  }

  function stopRecording() {
    if (recorderRef.current && recorderRef.current.state !== "inactive") {
      recorderRef.current.stop();
    }
    clearInterval(timerRef.current);
    setIsRecording(false);
    setProcessing(true);
  }

  function handleStop() {
    const blob = new Blob(chunksRef.current, { type: "video/webm" });
    const url = URL.createObjectURL(blob);
    const durationSec = seconds;
    stopStream();

    const tempVideo = document.createElement("video");
    tempVideo.src = url;
    tempVideo.muted = true;
    tempVideo.playsInline = true;
    tempVideo.onloadedmetadata = () => {
      try {
        tempVideo.currentTime = Math.min(0.3, (tempVideo.duration || 1) / 2);
      } catch (e) {
        finish(tempVideo.videoWidth, tempVideo.videoHeight);
      }
    };
    tempVideo.onseeked = () => finish(tempVideo.videoWidth, tempVideo.videoHeight);
    tempVideo.onerror = () => finish(0, 0);

    function finish(w, h) {
      const blurScore = w ? computeSharpness(tempVideo, w, h, { x: 0, y: 0, w: 1, h: 1 }) : 0;
      const focusScore = w ? computeSharpness(tempVideo, w, h, { x: 0.25, y: 0.25, w: 0.5, h: 0.5 }) : 0;
      setProcessing(false);
      onCaptured({ type: "video", url, width: w, height: h, durationSec, blurScore, focusScore, blob });
    }
  }

  const sharpPct = Math.min(100, Math.round((liveSharpness / 60) * 100));
  const focusGood = liveSharpness > SHARPNESS_THRESHOLD;

  return (
    <div className="dm-camera-screen">
      <div className="dm-camera-topbar">
        <button className="dm-icon-btn light" onClick={onCancel} aria-label="閉じる">
          <X size={20} />
        </button>
        <div className="dm-camera-project-name">{project.title}</div>
        <div style={{ width: 36 }} />
      </div>

      <div className="dm-camera-viewport">
        {error ? (
          <div className="dm-camera-error">
            <AlertCircle size={28} />
            <p>{error}</p>
            <button className="dm-secondary-btn" onClick={startCamera}>もう一度試す</button>
          </div>
        ) : (
          <>
            <video ref={videoRef} autoPlay playsInline muted className="dm-camera-video" />
            <div className="dm-live-meter">
              <span>{mode === "video" ? "ピント（リアルタイム推定）" : "ピント（リアルタイム推定）"}</span>
              <div className="dm-live-meter-track">
                <div
                  className="dm-live-meter-fill"
                  style={{ width: sharpPct + "%", background: focusGood ? "var(--success)" : "var(--momiji)" }}
                />
              </div>
              <span className="dm-live-meter-status">{focusGood ? "良好" : "ブレ・ボケに注意"}</span>
            </div>
            {isRecording && (
              <div className="dm-rec-badge">
                <span className="dm-rec-dot" /> REC {String(Math.floor(seconds / 60)).padStart(2, "0")}:{String(seconds % 60).padStart(2, "0")}
              </div>
            )}
            {processing && (
              <div className="dm-processing-overlay">処理中…</div>
            )}
          </>
        )}
      </div>

      <div className="dm-camera-controls">
        {project.dataType !== "photo" && project.dataType !== "video" ? null : null}
        {!error && (
          <>
            {project.dataType === "video" || project.dataType === "photo" ? (
              <div className="dm-mode-switch">
                <button
                  className={"dm-mode-btn" + (mode === "photo" ? " active" : "")}
                  onClick={() => !isRecording && setMode("photo")}
                >
                  <ImageIcon size={14} /> 写真
                </button>
                <button
                  className={"dm-mode-btn" + (mode === "video" ? " active" : "")}
                  onClick={() => !isRecording && setMode("video")}
                >
                  <Video size={14} /> 動画
                </button>
              </div>
            ) : null}

            <div className="dm-shutter-row">
              {mode === "photo" ? (
                <button className="dm-shutter-btn" onClick={takePhoto} aria-label="撮影する">
                  <Circle size={30} />
                </button>
              ) : isRecording ? (
                <button className="dm-shutter-btn recording" onClick={stopRecording} aria-label="録画停止">
                  <Square size={26} />
                </button>
              ) : (
                <button className="dm-shutter-btn" onClick={startRecording} aria-label="録画開始">
                  <Circle size={30} />
                </button>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

function PostScreen({ project, media, onRetake, onSubmit, onCancel }) {
  const [tags, setTags] = useState("");
  const [comment, setComment] = useState("");

  const resOk = media.width >= project.requirements.minWidth && media.height >= project.requirements.minHeight;
  const durOk =
    media.type === "photo"
      ? true
      : media.durationSec >= project.requirements.minDurationSec &&
        media.durationSec <= project.requirements.maxDurationSec;
  const blurOk = media.blurScore > SHARPNESS_THRESHOLD;
  const focusOk = media.focusScore > SHARPNESS_THRESHOLD;
  const allOk = resOk && durOk && blurOk && focusOk;

  const checks = [
    { label: "解像度チェック", ok: resOk, detail: `${media.width}×${media.height}px（必要：${project.requirements.minWidth}×${project.requirements.minHeight}以上）` },
    ...(media.type === "video"
      ? [{ label: "撮影時間チェック", ok: durOk, detail: `${media.durationSec}秒（必要：${project.requirements.minDurationSec}〜${project.requirements.maxDurationSec}秒）` }]
      : []),
    { label: "ブレ検知", ok: blurOk, detail: blurOk ? "手ブレは検出されませんでした" : "手ブレが検出されました。固定して撮り直してください" },
    { label: "ボケ検知（ピント）", ok: focusOk, detail: focusOk ? "ピントは合っています" : "ピントがぼけています。被写体に近づいて再撮影してください" },
  ];

  return (
    <div className="dm-content">
      <div className="dm-post-preview">
        {media.type === "photo" ? (
          <img src={media.url} alt="撮影プレビュー" />
        ) : (
          <video src={media.url} controls playsInline />
        )}
      </div>

      <div className={"dm-ai-summary" + (allOk ? " ok" : " ng")}>
        {allOk ? <CheckCircle2 size={18} /> : <XCircle size={18} />}
        <span>{allOk ? "AIチェックに合格しました。投稿できます" : "AIチェック未合格の項目があります。撮り直してください"}</span>
      </div>

      <div className="dm-check-card">
        {checks.map((c, i) => (
          <div key={i} className="dm-check-row">
            {c.ok ? <CheckCircle2 size={16} color="var(--success)" /> : <XCircle size={16} color="var(--momiji)" />}
            <div>
              <div className="dm-check-label">{c.label}</div>
              <div className="dm-check-detail">{c.detail}</div>
            </div>
          </div>
        ))}
        <div className="dm-check-note">※ブラウザ上で実行する簡易アルゴリズムによる推定値です。本番環境ではより高精度なモデルで判定します。</div>
      </div>

      {allOk && (
        <div className="dm-form">
          <label className="dm-field-label">タグ（任意・カンマ区切り）</label>
          <input className="dm-input" placeholder="例：和食,朝食,包丁" value={tags} onChange={(e) => setTags(e.target.value)} />
          <label className="dm-field-label">コメント（任意）</label>
          <textarea className="dm-textarea" rows={3} placeholder="撮影時の状況などがあれば記入してください" value={comment} onChange={(e) => setComment(e.target.value)} />
        </div>
      )}

      <div className="dm-post-actions">
        <button className="dm-secondary-btn full" onClick={onRetake}>
          <RotateCcw size={16} /> 撮り直す
        </button>
        <button
          className="dm-primary-btn"
          disabled={!allOk}
          onClick={() => onSubmit({ tags, comment })}
        >
          この内容で投稿する（{formatYen(project.reward)}）
        </button>
      </div>
    </div>
  );
}

function PostSuccessScreen({ project, go }) {
  return (
    <div className="dm-content center">
      <div className="dm-success-icon"><CheckCircle2 size={48} color="var(--success)" /></div>
      <div className="dm-success-title">投稿を送信しました</div>
      <p className="dm-success-text">
        「{project.title}」の投稿が企業のレビューに進みました。承認されると報酬 {formatYen(project.reward)} が確定します。
      </p>
      <button className="dm-primary-btn" onClick={() => go("wallet")}>報酬管理を見る</button>
      <button className="dm-link" style={{ marginTop: 12 }} onClick={() => go("projects")}>他の案件も見る</button>
    </div>
  );
}

function WalletScreen({ wallet, submissions, onApprove, onReject, onWithdraw }) {
  const [withdrawOpen, setWithdrawOpen] = useState(false);
  const [amount, setAmount] = useState("");
  const [withdrawMsg, setWithdrawMsg] = useState("");

  const pendingSubs = submissions.filter((s) => s.status === "企業レビュー中");
  const doneSubs = submissions.filter((s) => s.status !== "企業レビュー中");

  return (
    <div className="dm-content">
      <div className="dm-balance-card">
        <div className="dm-balance-label">受取可能残高</div>
        <div className="dm-balance-amount">{formatYen(wallet.balance)}</div>
        <div className="dm-balance-sub">審査中 {formatYen(wallet.pending)}</div>
        <button className="dm-withdraw-btn" onClick={() => setWithdrawOpen((v) => !v)}>
          <Download size={14} /> 出金申請する
        </button>
      </div>

      {withdrawOpen && (
        <div className="dm-withdraw-panel">
          <label className="dm-field-label">出金額（残高：{formatYen(wallet.balance)}）</label>
          <input
            className="dm-input"
            type="number"
            placeholder="金額を入力"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
          <button
            className="dm-primary-btn"
            onClick={() => {
              const n = Number(amount);
              if (!n || n <= 0 || n > wallet.balance) {
                setWithdrawMsg("有効な金額を入力してください");
                return;
              }
              onWithdraw(n);
              setWithdrawMsg(`${formatYen(n)}の出金申請を受け付けました（デモ：3営業日以内に振込予定）`);
              setAmount("");
            }}
          >
            申請する
          </button>
          {withdrawMsg && <div className="dm-withdraw-msg">{withdrawMsg}</div>}
        </div>
      )}

      {pendingSubs.length > 0 && (
        <>
          <div className="dm-section-title">審査中の投稿</div>
          <div className="dm-list">
            {pendingSubs.map((s) => (
              <div key={s.id} className="dm-submission-card">
                <div className="dm-submission-top">
                  <span className="dm-status-badge pending"><Clock size={11} /> 企業レビュー中</span>
                  <span className="dm-submission-reward">{formatYen(s.reward)}</span>
                </div>
                <div className="dm-submission-title">{s.projectTitle}</div>
                <div className="dm-submission-meta">投稿日時：{s.submittedAt}</div>
                <div className="dm-demo-actions">
                  <span className="dm-demo-label">デモ操作：</span>
                  <button className="dm-mini-btn approve" onClick={() => onApprove(s.id)}>企業承認をシミュレート</button>
                  <button className="dm-mini-btn reject" onClick={() => onReject(s.id)}>却下をシミュレート</button>
                </div>
              </div>
            ))}
          </div>
        </>
      )}

      <div className="dm-section-title">取引履歴</div>
      <div className="dm-list">
        {doneSubs.length === 0 && pendingSubs.length === 0 && (
          <div className="dm-empty">まだ投稿がありません。案件に参加して撮影してみましょう。</div>
        )}
        {doneSubs.map((s) => (
          <div key={s.id} className="dm-submission-card">
            <div className="dm-submission-top">
              <span className={"dm-status-badge " + (s.status === "承認" ? "approved" : "rejected")}>
                {s.status === "承認" ? <CheckCircle2 size={11} /> : <XCircle size={11} />} {s.status}
              </span>
              <span className="dm-submission-reward">{s.status === "承認" ? "+" : ""}{formatYen(s.status === "承認" ? s.reward : 0)}</span>
            </div>
            <div className="dm-submission-title">{s.projectTitle}</div>
            <div className="dm-submission-meta">投稿日時：{s.submittedAt}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function MyPageScreen({ submissions, wallet }) {
  const approved = submissions.filter((s) => s.status === "承認").length;
  return (
    <div className="dm-content">
      <div className="dm-profile-card">
        <div className="dm-avatar"><User size={26} color="var(--indigo)" /></div>
        <div>
          <div className="dm-profile-name">ゲストユーザー</div>
          <div className="dm-profile-sub">本人確認：未確認</div>
        </div>
      </div>
      <div className="dm-stat-grid">
        <div className="dm-stat-card">
          <TrendingUp size={16} color="var(--indigo)" />
          <div className="dm-stat-value">{submissions.length}</div>
          <div className="dm-stat-label">総投稿数</div>
        </div>
        <div className="dm-stat-card">
          <CheckCircle2 size={16} color="var(--success)" />
          <div className="dm-stat-value">{approved}</div>
          <div className="dm-stat-label">承認件数</div>
        </div>
        <div className="dm-stat-card">
          <WalletIcon size={16} color="var(--momiji)" />
          <div className="dm-stat-value">{formatYen(wallet.balance)}</div>
          <div className="dm-stat-label">累計残高</div>
        </div>
      </div>
      <div className="dm-menu-list">
        {["投稿履歴", "本人確認（KYC）", "通知設定", "銀行口座の登録", "ヘルプ・お問い合わせ"].map((m) => (
          <div key={m} className="dm-menu-item">
            <span>{m}</span>
            <ChevronRight size={16} color="var(--ink-soft)" />
          </div>
        ))}
      </div>
      <div className="dm-proto-note">
        これはプロトタイプです。データはこのセッション中のみ保持され、再読み込みでリセットされます。
      </div>
    </div>
  );
}

// ---------- root app ----------

export default function App() {
  const [screen, setScreen] = useState("home");
  const [projects, setProjects] = useState(INITIAL_PROJECTS);
  const [selectedId, setSelectedId] = useState(null);
  const [filterCategory, setFilterCategory] = useState("すべて");
  const [capturedMedia, setCapturedMedia] = useState(null);
  const [wallet, setWallet] = useState({ balance: 0, pending: 0 });
  const [submissions, setSubmissions] = useState([]);
  const [lastSubmittedProjectId, setLastSubmittedProjectId] = useState(null);

  const selectedProject = projects.find((p) => p.id === selectedId) || null;

  function go(target, opts) {
    if (target === "camera-entry") {
      setScreen("projects");
      return;
    }
    if (opts && opts.category) setFilterCategory(opts.category);
    setScreen(target);
  }

  function openProject(id) {
    setSelectedId(id);
    setScreen("detail");
  }

  function startShooting(project) {
    setSelectedId(project.id);
    setCapturedMedia(null);
    setScreen("camera");
  }

  function handleCaptured(media) {
    setCapturedMedia(media);
    setScreen("post");
  }

  function handleRetake() {
    setCapturedMedia(null);
    setScreen("camera");
  }

  function handleSubmit(extra) {
    const project = selectedProject;
    if (!project) return;
    const submission = {
      id: "s" + Date.now(),
      projectId: project.id,
      projectTitle: project.title,
      reward: project.reward,
      status: "企業レビュー中",
      submittedAt: nowStr(),
      tags: extra.tags,
      comment: extra.comment,
    };
    setSubmissions((prev) => [submission, ...prev]);
    setProjects((prev) =>
      prev.map((p) =>
        p.id === project.id
          ? { ...p, participantCount: Math.min(p.recruitCount, p.participantCount + 1) }
          : p
      )
    );
    setWallet((w) => ({ ...w, pending: w.pending + project.reward }));
    setLastSubmittedProjectId(project.id);
    setCapturedMedia(null);
    setScreen("post-success");
  }

  function handleApprove(id) {
    setSubmissions((prev) =>
      prev.map((s) => (s.id === id ? { ...s, status: "承認" } : s))
    );
    const sub = submissions.find((s) => s.id === id);
    if (sub) {
      setWallet((w) => ({ balance: w.balance + sub.reward, pending: Math.max(0, w.pending - sub.reward) }));
    }
  }

  function handleReject(id) {
    setSubmissions((prev) =>
      prev.map((s) => (s.id === id ? { ...s, status: "却下" } : s))
    );
    const sub = submissions.find((s) => s.id === id);
    if (sub) {
      setWallet((w) => ({ ...w, pending: Math.max(0, w.pending - sub.reward) }));
    }
  }

  function handleWithdraw(amount) {
    setWallet((w) => ({ ...w, balance: w.balance - amount }));
  }

  const isImmersive = screen === "camera";
  const showHeader = ["projects", "detail", "post", "wallet", "mypage"].includes(screen);
  const showBottomNav = ["home", "projects", "wallet", "mypage"].includes(screen);

  const headerTitleMap = {
    projects: "案件を探す",
    detail: selectedProject ? selectedProject.title : "",
    post: "投稿内容の確認",
    wallet: "報酬・ウォレット",
    mypage: "マイページ",
  };
  const headerBackMap = {
    projects: () => setScreen("home"),
    detail: () => setScreen("projects"),
    post: () => setScreen("camera"),
    wallet: null,
    mypage: null,
  };

  return (
    <div className="dm-root">
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Zen+Kaku+Gothic+New:wght@500;700;900&family=Noto+Sans+JP:wght@400;500;700&family=JetBrains+Mono:wght@500;700&display=swap');

        .dm-root {
          --paper: #F7F6F1;
          --card: #FFFFFF;
          --ink: #182620;
          --ink-soft: #5B6B64;
          --line: rgba(24,38,32,0.12);
          --indigo: #1E4B7A;
          --indigo-dark: #123252;
          --indigo-tint: #E7EEF4;
          --momiji: #C1440E;
          --momiji-tint: #FBEAE2;
          --sage: #5C7F63;
          --sage-tint: #EAF1EA;
          --success: #2F7D4F;
          --font-display: 'Zen Kaku Gothic New', 'Noto Sans JP', sans-serif;
          --font-body: 'Noto Sans JP', sans-serif;
          --font-mono: 'JetBrains Mono', monospace;

          width: 100%;
          max-width: 420px;
          margin: 0 auto;
          height: 780px;
          background: var(--paper);
          border: 1px solid var(--line);
          border-radius: 28px;
          overflow: hidden;
          display: flex;
          flex-direction: column;
          font-family: var(--font-body);
          color: var(--ink);
          position: relative;
        }
        .dm-root * { box-sizing: border-box; }
        .dm-root button { font-family: var(--font-body); cursor: pointer; }

        .dm-header {
          flex-shrink: 0;
          height: 52px;
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 8px;
          border-bottom: 1px solid var(--line);
          background: var(--card);
        }
        .dm-header-title { font-family: var(--font-display); font-weight: 700; font-size: 15px; }
        .dm-icon-btn {
          width: 36px; height: 36px; border-radius: 10px; border: none; background: transparent;
          display: flex; align-items: center; justify-content: center; color: var(--ink);
        }
        .dm-icon-btn:hover { background: var(--paper); }
        .dm-icon-btn.light { color: #fff; }

        .dm-content { flex: 1; overflow-y: auto; padding: 16px; }
        .dm-content.no-pad { padding: 0; }
        .dm-content.center { display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; padding: 32px; }

        .dm-eyebrow { font-size: 12px; color: var(--ink-soft); letter-spacing: 0.04em; }
        .dm-greeting { margin-bottom: 14px; }
        .dm-greeting-title { font-family: var(--font-display); font-weight: 700; font-size: 20px; margin-top: 2px; }

        .dm-wallet-card {
          width: 100%; display: flex; align-items: center; justify-content: space-between;
          background: var(--indigo); color: #fff; border: none; border-radius: 16px; padding: 16px;
          margin-bottom: 20px;
        }
        .dm-wallet-label { font-size: 12px; opacity: 0.85; }
        .dm-wallet-amount { font-family: var(--font-mono); font-weight: 700; font-size: 24px; margin-top: 2px; }
        .dm-wallet-pending { font-size: 11px; opacity: 0.85; margin-top: 4px; }

        .dm-section-head { display: flex; align-items: center; justify-content: space-between; margin: 18px 0 10px; }
        .dm-section-title { font-family: var(--font-display); font-weight: 700; font-size: 14px; }
        .dm-link { border: none; background: none; color: var(--indigo); font-size: 12px; font-weight: 500; }

        .dm-chip-row { display: flex; gap: 8px; overflow-x: auto; padding-bottom: 4px; }
        .dm-chip-row.scroll { margin-bottom: 14px; }
        .dm-category-tile {
          flex-shrink: 0; display: flex; flex-direction: column; align-items: center; gap: 6px;
          background: var(--card); border: 1px solid var(--line); border-radius: 14px; padding: 10px 14px;
          font-size: 11px; color: var(--ink);
        }
        .dm-filter-chip {
          flex-shrink: 0; border: 1px solid var(--line); background: var(--card); border-radius: 999px;
          padding: 6px 14px; font-size: 12px; color: var(--ink-soft);
        }
        .dm-filter-chip.active { background: var(--indigo); border-color: var(--indigo); color: #fff; }

        .dm-hscroll { display: flex; gap: 12px; overflow-x: auto; padding-bottom: 6px; }
        .dm-reco-card {
          flex-shrink: 0; width: 140px; text-align: left; background: var(--card); border: 1px solid var(--line);
          border-radius: 14px; padding: 10px; display: flex; flex-direction: column; gap: 8px;
        }
        .dm-reco-thumb { width: 100%; height: 72px; border-radius: 10px; display: flex; align-items: center; justify-content: center; }
        .dm-reco-title { font-size: 12px; font-weight: 500; line-height: 1.4; }
        .dm-reco-reward { font-family: var(--font-mono); font-size: 12px; color: var(--momiji); font-weight: 700; }

        .dm-search {
          display: flex; align-items: center; gap: 8px; background: var(--card); border: 1px solid var(--line);
          border-radius: 12px; padding: 10px 12px; margin-bottom: 12px;
        }
        .dm-search input { border: none; outline: none; flex: 1; font-size: 13px; background: transparent; color: var(--ink); }

        .dm-list { display: flex; flex-direction: column; gap: 10px; margin-top: 4px; }
        .dm-project-card {
          display: flex; gap: 12px; text-align: left; background: var(--card); border: 1px solid var(--line);
          border-radius: 14px; padding: 10px; border: 1px solid var(--line);
        }
        .dm-project-thumb {
          flex-shrink: 0; width: 76px; height: 76px; border-radius: 10px; display: flex; align-items: center; justify-content: center;
          position: relative;
        }
        .dm-datatype-badge {
          position: absolute; bottom: 4px; right: 4px; background: rgba(255,255,255,0.9); border-radius: 999px;
          font-size: 9px; padding: 2px 6px; display: flex; align-items: center; gap: 2px; color: var(--ink);
        }
        .dm-project-body { flex: 1; min-width: 0; }
        .dm-project-top { display: flex; align-items: center; justify-content: space-between; }
        .dm-project-category { font-size: 10px; color: var(--ink-soft); }
        .dm-badge-deadline { font-size: 10px; color: var(--momiji); display: flex; align-items: center; gap: 2px; }
        .dm-badge-closed { font-size: 10px; color: var(--ink-soft); background: var(--paper); padding: 2px 6px; border-radius: 6px; }
        .dm-project-title { font-weight: 700; font-size: 13px; margin: 2px 0; font-family: var(--font-display); }
        .dm-project-company { font-size: 11px; color: var(--ink-soft); margin-bottom: 6px; }
        .dm-project-bottom { display: flex; justify-content: space-between; align-items: center; margin-top: 6px; }
        .dm-project-participants { font-size: 10px; color: var(--ink-soft); display: flex; align-items: center; gap: 3px; }
        .dm-project-reward { font-family: var(--font-mono); font-weight: 700; font-size: 13px; color: var(--indigo); }

        .dm-progress { width: 100%; height: 5px; background: var(--paper); border-radius: 999px; overflow: hidden; margin-top: 2px; }
        .dm-progress-fill { height: 100%; background: var(--sage); border-radius: 999px; }

        .dm-empty { text-align: center; color: var(--ink-soft); font-size: 12px; padding: 40px 0; }

        .dm-detail-hero { height: 160px; display: flex; align-items: center; justify-content: center; }
        .dm-detail-body { padding: 16px; padding-bottom: 100px; }
        .dm-detail-title { font-family: var(--font-display); font-weight: 900; font-size: 19px; margin: 4px 0 14px; }
        .dm-detail-reward-row { display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 8px; }
        .dm-detail-reward-label { font-size: 11px; color: var(--ink-soft); }
        .dm-detail-reward { font-family: var(--font-mono); font-weight: 700; font-size: 24px; color: var(--momiji); }
        .dm-detail-meta { font-size: 11px; color: var(--ink-soft); text-align: right; display: flex; flex-direction: column; gap: 4px; }
        .dm-detail-meta div { display: flex; align-items: center; gap: 4px; justify-content: flex-end; }

        .dm-detail-section { margin-top: 20px; }
        .dm-detail-section-title { font-family: var(--font-display); font-weight: 700; font-size: 13px; margin-bottom: 8px; }
        .dm-check-list { list-style: none; padding: 0; margin: 0; display: flex; flex-direction: column; gap: 8px; }
        .dm-check-list li { font-size: 12px; color: var(--ink); padding-left: 14px; position: relative; line-height: 1.5; }
        .dm-check-list li::before { content: '―'; position: absolute; left: 0; color: var(--ink-soft); }

        .dm-sticky-cta { flex-shrink: 0; padding: 12px 16px; border-top: 1px solid var(--line); background: var(--card); }
        .dm-primary-btn {
          width: 100%; background: var(--indigo); color: #fff; border: none; border-radius: 12px; padding: 14px;
          font-weight: 700; font-size: 14px; font-family: var(--font-display);
        }
        .dm-primary-btn:disabled { background: var(--line); color: var(--ink-soft); }
        .dm-secondary-btn {
          background: var(--card); color: var(--ink); border: 1px solid var(--line); border-radius: 12px; padding: 12px;
          font-weight: 500; font-size: 13px; display: flex; align-items: center; justify-content: center; gap: 6px;
        }
        .dm-secondary-btn.full { width: 100%; margin-bottom: 8px; }

        /* camera */
        .dm-camera-screen { flex: 1; display: flex; flex-direction: column; background: #0E1512; min-height: 0; }
        .dm-camera-topbar { flex-shrink: 0; height: 52px; display: flex; align-items: center; justify-content: space-between; padding: 0 8px; }
        .dm-camera-project-name { color: #fff; font-size: 13px; font-weight: 500; }
        .dm-camera-viewport { flex: 1; position: relative; overflow: hidden; background: #000; min-height: 0; }
        .dm-camera-video { width: 100%; height: 100%; object-fit: cover; display: block; }
        .dm-camera-error { position: absolute; inset: 0; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 10px; color: #fff; padding: 24px; text-align: center; font-size: 12px; }

        .dm-live-meter { position: absolute; top: 12px; left: 12px; right: 12px; background: rgba(0,0,0,0.45); border-radius: 10px; padding: 8px 10px; display: flex; align-items: center; gap: 8px; }
        .dm-live-meter span { color: #fff; font-size: 10px; flex-shrink: 0; }
        .dm-live-meter-status { min-width: 66px; text-align: right; }
        .dm-live-meter-track { flex: 1; height: 5px; background: rgba(255,255,255,0.25); border-radius: 999px; overflow: hidden; }
        .dm-live-meter-fill { height: 100%; border-radius: 999px; transition: width 0.3s ease; }

        .dm-rec-badge { position: absolute; top: 56px; left: 12px; background: rgba(0,0,0,0.5); color: #fff; font-size: 11px; padding: 5px 10px; border-radius: 999px; display: flex; align-items: center; gap: 6px; font-family: var(--font-mono); }
        .dm-rec-dot { width: 8px; height: 8px; border-radius: 50%; background: var(--momiji); animation: dm-pulse 1s infinite; }
        @keyframes dm-pulse { 0%,100% { opacity: 1; } 50% { opacity: 0.3; } }
        .dm-processing-overlay { position: absolute; inset: 0; background: rgba(0,0,0,0.55); color: #fff; display: flex; align-items: center; justify-content: center; font-size: 13px; }

        .dm-camera-controls { flex-shrink: 0; padding: 14px 16px 20px; display: flex; flex-direction: column; align-items: center; gap: 14px; }
        .dm-mode-switch { display: flex; background: rgba(255,255,255,0.1); border-radius: 999px; padding: 4px; }
        .dm-mode-btn { border: none; background: none; color: rgba(255,255,255,0.7); font-size: 12px; padding: 6px 14px; border-radius: 999px; display: flex; align-items: center; gap: 5px; }
        .dm-mode-btn.active { background: #fff; color: var(--ink); font-weight: 700; }
        .dm-shutter-row { display: flex; align-items: center; justify-content: center; }
        .dm-shutter-btn { width: 68px; height: 68px; border-radius: 50%; border: 4px solid #fff; background: transparent; color: #fff; display: flex; align-items: center; justify-content: center; }
        .dm-shutter-btn svg { fill: #fff; }
        .dm-shutter-btn.recording svg { fill: var(--momiji); }
        .dm-shutter-btn.recording { border-color: var(--momiji); }

        /* post */
        .dm-post-preview { width: 100%; border-radius: 14px; overflow: hidden; background: #000; margin-bottom: 12px; max-height: 260px; display: flex; align-items: center; justify-content: center; }
        .dm-post-preview img, .dm-post-preview video { width: 100%; max-height: 260px; object-fit: contain; }
        .dm-ai-summary { display: flex; align-items: center; gap: 8px; padding: 10px 12px; border-radius: 12px; font-size: 12px; font-weight: 500; margin-bottom: 10px; }
        .dm-ai-summary.ok { background: #EAF6EF; color: var(--success); }
        .dm-ai-summary.ng { background: var(--momiji-tint); color: var(--momiji); }
        .dm-check-card { background: var(--card); border: 1px solid var(--line); border-radius: 14px; padding: 12px; display: flex; flex-direction: column; gap: 10px; margin-bottom: 14px; }
        .dm-check-row { display: flex; gap: 8px; align-items: flex-start; }
        .dm-check-label { font-size: 12px; font-weight: 700; }
        .dm-check-detail { font-size: 11px; color: var(--ink-soft); margin-top: 1px; }
        .dm-check-note { font-size: 10px; color: var(--ink-soft); border-top: 1px dashed var(--line); padding-top: 8px; margin-top: 2px; }

        .dm-form { margin-bottom: 16px; }
        .dm-field-label { font-size: 11px; color: var(--ink-soft); display: block; margin: 10px 0 6px; }
        .dm-input, .dm-textarea { width: 100%; border: 1px solid var(--line); border-radius: 10px; padding: 10px 12px; font-size: 13px; font-family: var(--font-body); color: var(--ink); background: var(--card); outline: none; }
        .dm-textarea { resize: none; }

        .dm-post-actions { display: flex; flex-direction: column; }

        .dm-success-icon { margin-bottom: 12px; }
        .dm-success-title { font-family: var(--font-display); font-weight: 900; font-size: 19px; margin-bottom: 8px; }
        .dm-success-text { font-size: 13px; color: var(--ink-soft); line-height: 1.6; margin-bottom: 20px; }

        /* wallet */
        .dm-balance-card { background: var(--indigo); color: #fff; border-radius: 16px; padding: 18px; margin-bottom: 18px; }
        .dm-balance-label { font-size: 12px; opacity: 0.85; }
        .dm-balance-amount { font-family: var(--font-mono); font-weight: 700; font-size: 30px; margin: 4px 0; }
        .dm-balance-sub { font-size: 11px; opacity: 0.85; margin-bottom: 12px; }
        .dm-withdraw-btn { background: rgba(255,255,255,0.15); color: #fff; border: none; border-radius: 10px; padding: 9px 14px; font-size: 12px; display: flex; align-items: center; gap: 6px; }
        .dm-withdraw-panel { background: var(--card); border: 1px solid var(--line); border-radius: 14px; padding: 14px; margin-bottom: 18px; }
        .dm-withdraw-msg { font-size: 11px; color: var(--success); margin-top: 8px; line-height: 1.5; }

        .dm-submission-card { background: var(--card); border: 1px solid var(--line); border-radius: 14px; padding: 12px; }
        .dm-submission-top { display: flex; justify-content: space-between; align-items: center; margin-bottom: 6px; }
        .dm-status-badge { font-size: 10px; padding: 3px 8px; border-radius: 999px; display: flex; align-items: center; gap: 4px; font-weight: 700; }
        .dm-status-badge.pending { background: var(--indigo-tint); color: var(--indigo); }
        .dm-status-badge.approved { background: #EAF6EF; color: var(--success); }
        .dm-status-badge.rejected { background: var(--momiji-tint); color: var(--momiji); }
        .dm-submission-reward { font-family: var(--font-mono); font-weight: 700; font-size: 13px; }
        .dm-submission-title { font-size: 13px; font-weight: 700; font-family: var(--font-display); }
        .dm-submission-meta { font-size: 10px; color: var(--ink-soft); margin-top: 3px; }
        .dm-demo-actions { margin-top: 10px; padding-top: 10px; border-top: 1px dashed var(--line); display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
        .dm-demo-label { font-size: 10px; color: var(--ink-soft); }
        .dm-mini-btn { font-size: 10px; border-radius: 999px; padding: 5px 10px; border: 1px solid var(--line); background: var(--paper); }
        .dm-mini-btn.approve { color: var(--success); border-color: var(--success); }
        .dm-mini-btn.reject { color: var(--momiji); border-color: var(--momiji); }

        /* mypage */
        .dm-profile-card { display: flex; align-items: center; gap: 12px; margin-bottom: 18px; }
        .dm-avatar { width: 52px; height: 52px; border-radius: 50%; background: var(--indigo-tint); display: flex; align-items: center; justify-content: center; }
        .dm-profile-name { font-weight: 700; font-size: 15px; font-family: var(--font-display); }
        .dm-profile-sub { font-size: 11px; color: var(--ink-soft); }
        .dm-stat-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin-bottom: 20px; }
        .dm-stat-card { background: var(--card); border: 1px solid var(--line); border-radius: 12px; padding: 10px; display: flex; flex-direction: column; gap: 4px; }
        .dm-stat-value { font-family: var(--font-mono); font-weight: 700; font-size: 14px; }
        .dm-stat-label { font-size: 10px; color: var(--ink-soft); }
        .dm-menu-list { display: flex; flex-direction: column; }
        .dm-menu-item { display: flex; justify-content: space-between; align-items: center; padding: 13px 2px; border-bottom: 1px solid var(--line); font-size: 13px; }
        .dm-proto-note { margin-top: 20px; font-size: 10px; color: var(--ink-soft); background: var(--card); border: 1px dashed var(--line); border-radius: 10px; padding: 10px; line-height: 1.5; }

        /* bottom nav */
        .dm-bottomnav { flex-shrink: 0; height: 66px; display: flex; align-items: center; border-top: 1px solid var(--line); background: var(--card); position: relative; }
        .dm-nav-item { flex: 1; height: 100%; border: none; background: none; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 3px; color: var(--ink-soft); font-size: 9px; }
        .dm-nav-item.active { color: var(--indigo); }
        .dm-nav-center {
          position: absolute; left: 50%; top: -18px; transform: translateX(-50%); width: 52px; height: 52px;
          border-radius: 50%; background: var(--momiji); color: #fff; border: 4px solid var(--paper);
          display: flex; align-items: center; justify-content: center;
        }
      `}</style>

      {isImmersive ? (
        <CameraScreen
          project={selectedProject}
          onCancel={() => setScreen("detail")}
          onCaptured={handleCaptured}
        />
      ) : (
        <>
          {showHeader && (
            <AppHeader title={headerTitleMap[screen]} onBack={headerBackMap[screen]} />
          )}

          {screen === "home" && (
            <HomeScreen projects={projects} wallet={wallet} go={go} openProject={openProject} />
          )}
          {screen === "projects" && (
            <ProjectsScreen
              projects={projects}
              filterCategory={filterCategory}
              setFilterCategory={setFilterCategory}
              openProject={openProject}
            />
          )}
          {screen === "detail" && (
            <ProjectDetailScreen project={selectedProject} go={go} startShooting={startShooting} />
          )}
          {screen === "post" && capturedMedia && selectedProject && (
            <PostScreen
              project={selectedProject}
              media={capturedMedia}
              onRetake={handleRetake}
              onSubmit={handleSubmit}
              onCancel={() => setScreen("detail")}
            />
          )}
          {screen === "post-success" && (
            <PostSuccessScreen
              project={projects.find((p) => p.id === lastSubmittedProjectId) || projects[0]}
              go={go}
            />
          )}
          {screen === "wallet" && (
            <WalletScreen
              wallet={wallet}
              submissions={submissions}
              onApprove={handleApprove}
              onReject={handleReject}
              onWithdraw={handleWithdraw}
            />
          )}
          {screen === "mypage" && <MyPageScreen submissions={submissions} wallet={wallet} />}

          {showBottomNav && <BottomNav screen={screen} go={go} />}
        </>
      )}
    </div>
  );
}
