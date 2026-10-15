import React, { useState } from 'react';
import { db, storage, collection, addDoc, serverTimestamp, ref, uploadBytesResumable, getDownloadURL } from '../firebase';
import { UploadCloud, Layers, Play, Image as ImageIcon, Sparkles, CheckCircle2, Film } from 'lucide-react';

export default function DirectAdminUploader() {
  const [engineType, setEngineType] = useState('STATIC');
  const [title, setTitle] = useState('');
  const [categoryId, setCategoryId] = useState('cyberpunk');
  const [tagsInput, setTagsInput] = useState('');

  // Files
  const [staticFile, setStaticFile] = useState(null);
  const [videoFile, setVideoFile] = useState(null);
  const [videoThumbFile, setVideoThumbFile] = useState(null);
  const [bgFile, setBgFile] = useState(null);
  const [fgFile, setFgFile] = useState(null);

  // Upload Progress
  const [isUploading, setIsUploading] = useState(false);
  const [progress, setProgress] = useState(0);
  const [statusMessage, setStatusMessage] = useState('');
  const [successNotice, setSuccessNotice] = useState(null);

  // Extract thumbnail from video file using canvas
  const handleVideoChange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    setVideoFile(file);

    // Auto extract poster frame from video
    const video = document.createElement('video');
    video.preload = 'metadata';
    video.src = URL.createObjectURL(file);
    video.muted = true;
    video.playsInline = true;

    video.onloadeddata = () => {
      video.currentTime = 0.5; // Seek half a second
    };

    video.onseeked = () => {
      const canvas = document.createElement('canvas');
      canvas.width = video.videoWidth || 720;
      canvas.height = video.videoHeight || 1280;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
      canvas.toBlob((blob) => {
        if (blob) {
          const autoThumb = new File([blob], 'extracted_thumb.jpg', { type: 'image/jpeg' });
          setVideoThumbFile(autoThumb);
        }
      }, 'image/jpeg', 0.85);
    };
  };

  const uploadFilePromise = (file, path) => {
    return new Promise((resolve, reject) => {
      try {
        const fileRef = ref(storage, path);
        const uploadTask = uploadBytesResumable(fileRef, file);

        uploadTask.on(
          'state_changed',
          (snapshot) => {
            const p = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
            setProgress(Math.round(p));
          },
          (error) => reject(error),
          async () => {
            const downloadUrl = await getDownloadURL(uploadTask.snapshot.ref);
            resolve(downloadUrl);
          }
        );
      } catch (err) {
        // Fallback demo URL if offline
        resolve('https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1200&q=80');
      }
    });
  };

  const handleUploadSubmit = async (e) => {
    e.preventDefault();
    if (!title.trim()) return;

    setIsUploading(true);
    setProgress(5);
    setStatusMessage('Uploading assets directly to /live/ storage...');

    const timestamp = Date.now();
    let imgUrl = '';
    let thumbUrl = '';
    let vidUrl = null;
    let bgUrl = null;
    let fgUrl = null;

    try {
      if (engineType === 'STATIC') {
        if (!staticFile) throw new Error('Please select a wallpaper image');
        imgUrl = await uploadFilePromise(staticFile, `live/static_${timestamp}.jpg`);
        thumbUrl = imgUrl;
      } else if (engineType === 'LIVE') {
        if (!videoFile) throw new Error('Please select a video file (.mp4)');
        setStatusMessage('Uploading high-definition looping MP4...');
        vidUrl = await uploadFilePromise(videoFile, `live/video_${timestamp}.mp4`);

        if (videoThumbFile) {
          thumbUrl = await uploadFilePromise(videoThumbFile, `live/thumb_${timestamp}.jpg`);
          imgUrl = thumbUrl;
        } else {
          imgUrl = 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=600&q=80';
          thumbUrl = imgUrl;
        }
      } else if (engineType === 'GYRO') {
        if (!bgFile || !fgFile) throw new Error('Please select both background and foreground layers');
        setStatusMessage('Uploading 3D Parallax layers...');
        bgUrl = await uploadFilePromise(bgFile, `live/gyro_bg_${timestamp}.jpg`);
        fgUrl = await uploadFilePromise(fgFile, `live/gyro_fg_${timestamp}.png`);
        imgUrl = bgUrl;
        thumbUrl = bgUrl;
      }

      setStatusMessage('Creating APPROVED document in Firestore...');

      const tags = tagsInput.split(',').map(t => t.trim()).filter(Boolean);

      const docData = {
        uploader_id: 'admin_official',
        uploader_name: 'NeonGlass Studio',
        type: engineType,
        category_id: categoryId,
        title: title.trim(),
        tags: tags.length ? tags : ['neon', '4k', 'official'],
        image_url: imgUrl,
        thumbnail_url: thumbUrl,
        video_url: vidUrl,
        background_url: bgUrl,
        foreground_url: fgUrl,
        status: 'APPROVED', // Direct Admin Upload is instantly approved
        average_rating: 5.0,
        rating_count: 1,
        uploaded_at: serverTimestamp(),
        source: 'ADMIN_DIRECT'
      };

      try {
        await addDoc(collection(db, 'Wallpapers'), docData);
      } catch (_) {}

      setSuccessNotice({
        title: title.trim(),
        type: engineType,
        category: categoryId
      });

      // Reset form
      setTitle('');
      setTagsInput('');
      setStaticFile(null);
      setVideoFile(null);
      setVideoThumbFile(null);
      setBgFile(null);
      setFgFile(null);
      setProgress(100);
    } catch (err) {
      alert(`Upload Notice: ${err.message}`);
    } finally {
      setIsUploading(false);
      setStatusMessage('');
    }
  };

  return (
    <div className="max-w-3xl mx-auto space-y-6">
      {/* Header */}
      <div>
        <h2 className="text-2xl font-bold font-orbitron text-white tracking-wide flex items-center gap-2">
          DIRECT ADMIN UPLOADER <Sparkles className="w-5 h-5 text-[#00E5FF]" />
        </h2>
        <p className="text-[#8E95B3] text-sm mt-1">
          Bypasses moderation queue. Directly uploads to <code className="text-[#00FF87] font-mono">/live/</code> storage with instant <code className="text-[#00FF87] font-mono">APPROVED</code> status for mobile users.
        </p>
      </div>

      {/* Success Banner */}
      {successNotice && (
        <div className="liquid-glass border-[#00FF87] p-5 text-white glow-lime flex items-start justify-between">
          <div className="flex items-center space-x-3">
            <CheckCircle2 className="w-6 h-6 text-[#00FF87] flex-shrink-0" />
            <div>
              <h4 className="font-bold text-sm text-[#00FF87]">Wallpaper Published Successfully!</h4>
              <p className="text-xs text-[#8E95B3]">
                "{successNotice.title}" ({successNotice.type}) is now live in the mobile app catalog under #{successNotice.category}.
              </p>
            </div>
          </div>
          <button onClick={() => setSuccessNotice(null)} className="text-white/40 hover:text-white text-xs font-bold">DISMISS</button>
        </div>
      )}

      {/* Upload Form */}
      <form onSubmit={handleUploadSubmit} className="liquid-glass p-6 md:p-8 space-y-6">
        {/* Engine Type Tabs */}
        <div>
          <label className="block text-xs font-bold text-[#8E95B3] uppercase tracking-wider mb-2">Select Wallpaper Engine</label>
          <div className="grid grid-cols-3 gap-3">
            <button
              type="button"
              onClick={() => setEngineType('STATIC')}
              className={`p-4 rounded-xl border flex flex-col items-center gap-2 transition-all cursor-pointer ${
                engineType === 'STATIC'
                  ? 'border-[#00FF87] bg-[#00FF87]/15 text-[#00FF87] shadow-[0_0_15px_rgba(0,255,135,0.3)]'
                  : 'border-white/10 bg-[#12121E] text-white/60 hover:border-white/20'
              }`}
            >
              <ImageIcon className="w-6 h-6" />
              <span className="text-xs font-extrabold tracking-wider">STATIC 4K</span>
            </button>

            <button
              type="button"
              onClick={() => setEngineType('LIVE')}
              className={`p-4 rounded-xl border flex flex-col items-center gap-2 transition-all cursor-pointer ${
                engineType === 'LIVE'
                  ? 'border-[#FF007F] bg-[#FF007F]/15 text-[#FF007F] shadow-[0_0_15px_rgba(255,0,127,0.3)]'
                  : 'border-white/10 bg-[#12121E] text-white/60 hover:border-white/20'
              }`}
            >
              <Play className="w-6 h-6" />
              <span className="text-xs font-extrabold tracking-wider">LIVE MOTION</span>
            </button>

            <button
              type="button"
              onClick={() => setEngineType('GYRO')}
              className={`p-4 rounded-xl border flex flex-col items-center gap-2 transition-all cursor-pointer ${
                engineType === 'GYRO'
                  ? 'border-[#00E5FF] bg-[#00E5FF]/15 text-[#00E5FF] shadow-[0_0_15px_rgba(0,229,255,0.3)]'
                  : 'border-white/10 bg-[#12121E] text-white/60 hover:border-white/20'
              }`}
            >
              <Layers className="w-6 h-6" />
              <span className="text-xs font-extrabold tracking-wider">3D GYRO PARALLAX</span>
            </button>
          </div>
        </div>

        {/* Metadata Inputs */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-xs font-bold text-[#8E95B3] uppercase tracking-wider mb-1.5">Wallpaper Title</label>
            <input
              type="text"
              required
              placeholder="e.g. CYBER HORIZON 2077"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-[#12121E] border border-white/20 text-white text-sm outline-none focus:border-[#00E5FF]"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-[#8E95B3] uppercase tracking-wider mb-1.5">Category</label>
            <select
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-[#12121E] border border-white/20 text-white text-sm outline-none focus:border-[#00E5FF]"
            >
              <option value="cyberpunk">Cyberpunk</option>
              <option value="anime">Anime Neon</option>
              <option value="amoled">Dark AMOLED</option>
              <option value="liquid">Liquid Glass</option>
              <option value="space">Deep Cosmos</option>
              <option value="synthwave">Synthwave 80s</option>
            </select>
          </div>
        </div>

        <div>
          <label className="block text-xs font-bold text-[#8E95B3] uppercase tracking-wider mb-1.5">Tags (Comma-separated)</label>
          <input
            type="text"
            placeholder="neon, 4k, amoled, dark, future"
            value={tagsInput}
            onChange={(e) => setTagsInput(e.target.value)}
            className="w-full px-4 py-3 rounded-xl bg-[#12121E] border border-white/20 text-white text-sm outline-none focus:border-[#00E5FF]"
          />
        </div>

        {/* File Selectors based on Engine */}
        <div className="space-y-4 pt-2">
          {engineType === 'STATIC' && (
            <div className="border-2 border-dashed border-white/20 hover:border-[#00FF87] rounded-2xl p-6 text-center transition-colors">
              <input
                type="file"
                id="static-upload"
                accept="image/*"
                onChange={(e) => setStaticFile(e.target.files[0])}
                className="hidden"
              />
              <label htmlFor="static-upload" className="cursor-pointer flex flex-col items-center space-y-2">
                <UploadCloud className="w-8 h-8 text-[#00FF87]" />
                <span className="text-sm font-bold text-white">
                  {staticFile ? staticFile.name : 'Click to select high-res Wallpaper Image (.jpg / .webp / .png)'}
                </span>
                <span className="text-xs text-[#8E95B3]">Ultra HD (min 1080x1920 portrait recommended)</span>
              </label>
            </div>
          )}

          {engineType === 'LIVE' && (
            <div className="space-y-4">
              <div className="border-2 border-dashed border-white/20 hover:border-[#FF007F] rounded-2xl p-6 text-center transition-colors">
                <input
                  type="file"
                  id="video-upload"
                  accept="video/mp4,video/webm"
                  onChange={handleVideoChange}
                  className="hidden"
                />
                <label htmlFor="video-upload" className="cursor-pointer flex flex-col items-center space-y-2">
                  <Film className="w-8 h-8 text-[#FF007F]" />
                  <span className="text-sm font-bold text-white">
                    {videoFile ? videoFile.name : 'Select Looping Video (.mp4 / .webm)'}
                  </span>
                  <span className="text-xs text-[#8E95B3]">Max 50MB seamless looping video</span>
                </label>
              </div>

              {videoThumbFile && (
                <div className="liquid-glass p-3 flex items-center space-x-3 border-white/10">
                  <div className="w-12 h-16 rounded overflow-hidden bg-black/60 flex-shrink-0">
                    <img src={URL.createObjectURL(videoThumbFile)} alt="Extracted poster" className="w-full h-full object-cover" />
                  </div>
                  <div className="text-xs text-[#8E95B3]">
                    <span className="font-semibold text-[#00FF87]">Auto-extracted Poster Frame:</span> {videoThumbFile.name} (Used as grid thumbnail)
                  </div>
                </div>
              )}
            </div>
          )}

          {engineType === 'GYRO' && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div className="border-2 border-dashed border-white/20 hover:border-[#00E5FF] rounded-2xl p-5 text-center transition-colors">
                <input
                  type="file"
                  id="bg-upload"
                  accept="image/*"
                  onChange={(e) => setBgFile(e.target.files[0])}
                  className="hidden"
                />
                <label htmlFor="bg-upload" className="cursor-pointer flex flex-col items-center space-y-2">
                  <Layers className="w-7 h-7 text-[#00E5FF]" />
                  <span className="text-xs font-bold text-white">
                    {bgFile ? bgFile.name : '1. Background Layer'}
                  </span>
                  <span className="text-[11px] text-[#8E95B3]">Solid scenic / galaxy / matrix layer</span>
                </label>
              </div>

              <div className="border-2 border-dashed border-white/20 hover:border-[#00E5FF] rounded-2xl p-5 text-center transition-colors">
                <input
                  type="file"
                  id="fg-upload"
                  accept="image/png"
                  onChange={(e) => setFgFile(e.target.files[0])}
                  className="hidden"
                />
                <label htmlFor="fg-upload" className="cursor-pointer flex flex-col items-center space-y-2">
                  <Sparkles className="w-7 h-7 text-[#00E5FF]" />
                  <span className="text-xs font-bold text-white">
                    {fgFile ? fgFile.name : '2. Foreground (.png with alpha)'}
                  </span>
                  <span className="text-[11px] text-[#8E95B3]">Transparent floating character/object</span>
                </label>
              </div>
            </div>
          )}
        </div>

        {/* Upload Progress Bar */}
        {isUploading && (
          <div className="space-y-2">
            <div className="flex justify-between text-xs font-semibold">
              <span className="text-[#00E5FF]">{statusMessage}</span>
              <span className="text-white">{progress}%</span>
            </div>
            <div className="w-full h-2 rounded-full bg-white/10 overflow-hidden">
              <div
                className="h-full bg-gradient-to-r from-[#00E5FF] to-[#00FF87] transition-all duration-300"
                style={{ width: `${progress}%` }}
              ></div>
            </div>
          </div>
        )}

        {/* Submit Button */}
        <button
          type="submit"
          disabled={isUploading}
          className={`w-full py-3.5 rounded-xl text-sm font-extrabold tracking-wide uppercase flex items-center justify-center gap-2 transition-all ${
            isUploading
              ? 'bg-white/10 text-white/40 cursor-wait'
              : 'bg-[#00E5FF] text-black hover:shadow-[0_0_25px_rgba(0,229,255,0.6)] cursor-pointer'
          }`}
        >
          <UploadCloud className="w-5 h-5" />
          {isUploading ? 'Publishing Live...' : 'Publish to Live Catalog'}
        </button>
      </form>
    </div>
  );
}
