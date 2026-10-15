import React, { useState, useEffect } from 'react';
import { db, collection, query, where, getDocs, doc, updateDoc, writeBatch } from '../firebase';
import { Check, X, Eye, Edit3, Layers, Play, Image as ImageIcon, Sparkles, AlertCircle } from 'lucide-react';

const MOCK_PENDING = [
  {
    id: 'pending_demo_1',
    uploader_id: 'user_neo_99',
    uploader_name: 'NeoTokyoArtist',
    type: 'STATIC',
    category_id: 'cyberpunk',
    title: 'NEO SHINJUKU OVERDRIVE',
    tags: ['shinjuku', 'rain', 'tokyo', 'neon'],
    image_url: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=1200&q=80',
    thumbnail_url: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=400&q=80',
    status: 'PENDING',
    uploaded_at: new Date().toISOString()
  },
  {
    id: 'pending_demo_2',
    uploader_id: 'user_holo_42',
    uploader_name: 'HoloDimension',
    type: 'GYRO',
    category_id: 'liquid',
    title: 'NEON MECHA PARALLAX',
    tags: ['mecha', 'gyro', '3d', 'future'],
    image_url: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1200&q=80',
    thumbnail_url: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=400&q=80',
    background_url: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=1200&q=80',
    foreground_url: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/6.png',
    status: 'PENDING',
    uploaded_at: new Date().toISOString()
  },
  {
    id: 'pending_demo_3',
    uploader_id: 'user_vibe_77',
    uploader_name: 'VibeFlow',
    type: 'LIVE',
    category_id: 'synthwave',
    title: 'CYBER TUNNEL 60FPS',
    tags: ['tunnel', 'live', 'video', 'retro'],
    image_url: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=400&q=80',
    thumbnail_url: 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=400&q=80',
    video_url: 'https://assets.mixkit.co/videos/preview/mixkit-tunnel-of-futuristic-neon-lights-seamless-loop-41584-large.mp4',
    status: 'PENDING',
    uploaded_at: new Date().toISOString()
  }
];

export default function ModerationQueue() {
  const [items, setItems] = useState(MOCK_PENDING);
  const [loading, setLoading] = useState(false);
  const [selectedIds, setSelectedIds] = useState([]);
  const [previewItem, setPreviewItem] = useState(null);
  const [rejectModalItem, setRejectModalItem] = useState(null);
  const [rejectReason, setRejectReason] = useState('');
  const [isBulkReject, setIsBulkReject] = useState(false);
  const [notification, setNotification] = useState('');

  const REJECTION_PRESETS = [
    'Low resolution or blurry artwork',
    'Watermark, timestamp or external brand logo detected',
    'Does not match selected category/style tags',
    'Inappropriate or offensive imagery',
    'Copyright infringement or non-original work',
    'Incorrect layer formatting for 3D/Live parallax',
  ];

  useEffect(() => {
    fetchPending();
    const interval = setInterval(() => {
      fetchPending(false);
    }, 3500);
    return () => clearInterval(interval);
  }, []);

  const fetchPending = async (showLoading = true) => {
    if (showLoading) setLoading(true);
    try {
      let combined = [];

      // 1. Check local device bridge first (fastest, receives live mobile app uploads)
      try {
        const localRes = await fetch('/api/wallpapers/pending');
        if (localRes.ok) {
          const localList = await localRes.json();
          if (Array.isArray(localList)) {
            combined = [...localList];
          }
        }
      } catch (_) {}

      // 2. Query Firestore if online
      try {
        const q = query(collection(db, 'Wallpapers'), where('status', '==', 'PENDING'));
        const snapshot = await getDocs(q);
        if (!snapshot.empty) {
          const firestoreList = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));
          firestoreList.forEach(item => {
            if (!combined.some(c => c.id === item.id)) {
              combined.push(item);
            }
          });
        }
      } catch (_) {}

      // 3. Fallback to mock demo items if queue is empty
      if (combined.length > 0) {
        setItems(combined);
      } else {
        setItems(MOCK_PENDING);
      }
    } catch (_) {
      setItems(MOCK_PENDING);
    } finally {
      if (showLoading) setLoading(false);
    }
  };

  const notify = (msg) => {
    setNotification(msg);
    setTimeout(() => setNotification(''), 3500);
  };

  const handleApprove = async (id) => {
    try {
      await updateDoc(doc(db, 'Wallpapers', id), { status: 'APPROVED' });
    } catch (_) {}
    try {
      await fetch(`/api/wallpapers/${id}/approve`, { method: 'POST' });
    } catch (_) {}
    setItems(prev => prev.filter(item => item.id !== id));
    setSelectedIds(prev => prev.filter(i => i !== id));
    notify(`Wallpaper approved & now LIVE on user app!`);
  };

  const handleOpenRejectModal = (item) => {
    setRejectModalItem(item);
    setRejectReason('');
    setIsBulkReject(false);
  };

  const handleOpenBulkRejectModal = () => {
    if (!selectedIds.length) return;
    setRejectModalItem({ id: 'bulk', title: `${selectedIds.length} Wallpapers Selected` });
    setRejectReason('');
    setIsBulkReject(true);
  };

  const handleConfirmReject = async () => {
    if (!rejectModalItem) return;
    const finalReason = rejectReason.trim() || 'Does not meet community neon guidelines.';

    if (isBulkReject) {
      const idsToReject = [...selectedIds];
      try {
        const batch = writeBatch(db);
        idsToReject.forEach(id => {
          batch.update(doc(db, 'Wallpapers', id), {
            status: 'REJECTED',
            rejection_reason: finalReason,
            rejectionReason: finalReason,
          });
        });
        await batch.commit();
      } catch (_) {}

      for (const id of idsToReject) {
        try {
          await fetch(`/api/wallpapers/${id}/reject`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ reason: finalReason }),
          });
        } catch (_) {}
      }

      setItems(prev => prev.filter(item => !idsToReject.includes(item.id)));
      setSelectedIds([]);
      notify(`Rejected ${idsToReject.length} wallpapers with reason: "${finalReason}"`);
    } else {
      const id = rejectModalItem.id;
      try {
        await updateDoc(doc(db, 'Wallpapers', id), {
          status: 'REJECTED',
          rejection_reason: finalReason,
          rejectionReason: finalReason,
        });
      } catch (_) {}
      try {
        await fetch(`/api/wallpapers/${id}/reject`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ reason: finalReason }),
        });
      } catch (_) {}

      setItems(prev => prev.filter(item => item.id !== id));
      setSelectedIds(prev => prev.filter(i => i !== id));
      notify(`Rejected "${rejectModalItem.title}". Reason sent to creator.`);
    }

    // Disappear after confirm
    setRejectModalItem(null);
    setRejectReason('');
    setIsBulkReject(false);
    if (previewItem && (!isBulkReject && previewItem.id === rejectModalItem?.id)) {
      setPreviewItem(null);
    }
  };

  const handleBulkApprove = async () => {
    if (!selectedIds.length) return;
    try {
      const batch = writeBatch(db);
      selectedIds.forEach(id => {
        batch.update(doc(db, 'Wallpapers', id), { status: 'APPROVED' });
      });
      await batch.commit();
    } catch (_) {}
    for (const id of selectedIds) {
      try {
        await fetch(`/api/wallpapers/${id}/approve`, { method: 'POST' });
      } catch (_) {}
    }
    setItems(prev => prev.filter(item => !selectedIds.includes(item.id)));
    notify(`Bulk approved ${selectedIds.length} wallpapers! Now LIVE on user side.`);
    setSelectedIds([]);
  };

  const toggleSelect = (id) => {
    setSelectedIds(prev =>
      prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]
    );
  };

  const selectAll = () => {
    if (selectedIds.length === items.length) {
      setSelectedIds([]);
    } else {
      setSelectedIds(items.map(i => i.id));
    }
  };

  return (
    <div className="space-y-6">
      {/* Top Banner Alert */}
      {notification && (
        <div className="liquid-glass border-[#00FF87] p-4 text-[#00FF87] flex items-center space-x-3 glow-lime animate-pulse">
          <Sparkles className="w-5 h-5 flex-shrink-0" />
          <span className="font-semibold text-sm">{notification}</span>
        </div>
      )}

      {/* Header Bar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold font-orbitron text-white tracking-wide flex items-center gap-2">
            MODERATION QUEUE <span className="text-xs px-2.5 py-1 rounded-full bg-[#FFB800]/20 text-[#FFB800] border border-[#FFB800]/50">{items.length} PENDING</span>
          </h2>
          <p className="text-[#8E95B3] text-sm mt-1">Review community creator submissions before publishing live to mobile users.</p>
        </div>

        {/* Bulk Action Controls */}
        <div className="flex items-center space-x-3">
          <button
            onClick={selectAll}
            className="px-3 py-2 rounded-xl text-xs font-semibold bg-[#12121E] border border-white/20 hover:border-[#00E5FF] text-white transition-all"
          >
            {selectedIds.length === items.length ? 'Deselect All' : 'Select All'}
          </button>
          <button
            onClick={handleBulkApprove}
            disabled={!selectedIds.length}
            className={`px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-all ${
              selectedIds.length
                ? 'bg-[#00FF87] text-black hover:shadow-[0_0_15px_rgba(0,255,135,0.6)] cursor-pointer'
                : 'bg-white/10 text-white/40 cursor-not-allowed'
            }`}
          >
            <Check className="w-4 h-4" /> Approve ({selectedIds.length})
          </button>
          <button
            onClick={handleOpenBulkRejectModal}
            disabled={!selectedIds.length}
            className={`px-4 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-all ${
              selectedIds.length
                ? 'bg-[#FF007F] text-white hover:shadow-[0_0_15px_rgba(255,0,127,0.6)] cursor-pointer'
                : 'bg-white/10 text-white/40 cursor-not-allowed'
            }`}
          >
            <X className="w-4 h-4" /> Reject ({selectedIds.length})
          </button>
        </div>
      </div>

      {/* Queue Grid */}
      {items.length === 0 ? (
        <div className="liquid-glass p-12 text-center text-[#8E95B3]">
          <Check className="w-12 h-12 text-[#00FF87] mx-auto mb-3" />
          <h3 className="text-lg font-bold text-white">Queue is Clear!</h3>
          <p className="text-sm">All community creator uploads have been processed.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {items.map(item => (
            <div
              key={item.id}
              className={`liquid-glass-card overflow-hidden flex flex-col justify-between ${
                selectedIds.includes(item.id) ? 'border-[#00E5FF] ring-2 ring-[#00E5FF]/40' : ''
              }`}
            >
              {/* Media Thumbnail */}
              <div className="relative aspect-[9/13] w-full bg-black/60 overflow-hidden group">
                <img
                  src={item.thumbnail_url || item.image_url}
                  alt={item.title}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />

                {/* Checkbox Overlay */}
                <button
                  onClick={() => toggleSelect(item.id)}
                  className="absolute top-3 left-3 w-7 h-7 rounded-lg bg-black/70 backdrop-blur-md border border-white/20 flex items-center justify-center cursor-pointer hover:border-[#00E5FF]"
                >
                  {selectedIds.includes(item.id) && <Check className="w-4 h-4 text-[#00E5FF]" />}
                </button>

                {/* Type Badge */}
                <div className="absolute top-3 right-3 px-2.5 py-1 rounded-full text-[10px] font-black tracking-wider bg-black/75 backdrop-blur-md border border-white/20 flex items-center gap-1 text-white">
                  {item.type === 'GYRO' && <Layers className="w-3 h-3 text-[#00E5FF]" />}
                  {item.type === 'LIVE' && <Play className="w-3 h-3 text-[#FF007F]" />}
                  {item.type === 'STATIC' && <ImageIcon className="w-3 h-3 text-[#00FF87]" />}
                  <span>{item.type}</span>
                </div>

                {/* Hover Preview Button */}
                <button
                  onClick={() => setPreviewItem(item)}
                  className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 flex items-center justify-center gap-2 text-white font-bold text-sm transition-opacity"
                >
                  <Eye className="w-5 h-5 text-[#00E5FF]" /> Click to Inspect
                </button>
              </div>

              {/* Meta & Editing */}
              <div className="p-4 space-y-3">
                <div className="flex justify-between items-start">
                  <div>
                    <h4 className="font-bold text-white text-base truncate max-w-[200px]">{item.title}</h4>
                    <p className="text-xs text-[#8E95B3]">By: <span className="text-[#00E5FF] font-medium">{item.uploader_name}</span></p>
                  </div>
                  <span className="text-[11px] px-2 py-0.5 rounded bg-white/5 border border-white/10 text-white/70 uppercase">
                    {item.category_id}
                  </span>
                </div>

                {/* Tags */}
                <div className="flex flex-wrap gap-1">
                  {item.tags?.map((t, idx) => (
                    <span key={idx} className="text-[10px] px-2 py-0.5 rounded bg-[#1A1A2E] text-[#8E95B3]">#{t}</span>
                  ))}
                </div>

                {/* Action Buttons */}
                <div className="pt-2 flex items-center space-x-2 border-t border-white/10">
                  <button
                    onClick={() => handleApprove(item.id)}
                    className="flex-1 py-2 rounded-xl text-xs font-bold bg-[#00FF87]/20 border border-[#00FF87]/60 text-[#00FF87] hover:bg-[#00FF87] hover:text-black transition-all flex items-center justify-center gap-1 cursor-pointer"
                  >
                    <Check className="w-3.5 h-3.5" /> Approve
                  </button>
                  <button
                    onClick={() => handleOpenRejectModal(item)}
                    className="flex-1 py-2 rounded-xl text-xs font-bold bg-[#FF007F]/20 border border-[#FF007F]/60 text-[#FF007F] hover:bg-[#FF007F] hover:text-white transition-all flex items-center justify-center gap-1 cursor-pointer"
                  >
                    <X className="w-3.5 h-3.5" /> Reject
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Inspect Preview Modal */}
      {previewItem && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
          <div className="liquid-glass max-w-2xl w-full p-6 space-y-4 max-h-[90vh] overflow-y-auto border-[#00E5FF] glow-cyan">
            <div className="flex justify-between items-center border-b border-white/10 pb-3">
              <h3 className="font-orbitron font-bold text-lg text-white flex items-center gap-2">
                <Eye className="w-5 h-5 text-[#00E5FF]" /> {previewItem.title}
              </h3>
              <button onClick={() => setPreviewItem(null)} className="text-white/60 hover:text-white cursor-pointer">
                <X className="w-6 h-6" />
              </button>
            </div>

            {/* Content Display based on Engine */}
            <div className="flex justify-center bg-black/70 rounded-xl overflow-hidden max-h-[500px]">
              {previewItem.type === 'LIVE' && previewItem.video_url ? (
                <video src={previewItem.video_url} autoPlay loop muted controls className="max-h-[480px] w-auto" />
              ) : previewItem.type === 'GYRO' ? (
                <div className="relative w-full aspect-[9/16] max-w-[320px] overflow-hidden rounded-lg">
                  <img src={previewItem.background_url || previewItem.image_url} alt="Background" className="absolute inset-0 w-full h-full object-cover scale-110" />
                  <img src={previewItem.foreground_url} alt="Foreground" className="absolute inset-0 w-full h-full object-contain scale-95" />
                  <div className="absolute top-2 right-2 text-[10px] px-2 py-1 rounded bg-black/70 text-[#00E5FF] border border-[#00E5FF]">2-Layer 3D Gyro</div>
                </div>
              ) : (
                <img src={previewItem.image_url} alt={previewItem.title} className="max-h-[480px] w-auto object-contain" />
              )}
            </div>

            <div className="space-y-2 text-sm text-[#8E95B3]">
              <p><strong className="text-white">Uploader:</strong> {previewItem.uploader_name} ({previewItem.uploader_id})</p>
              <p><strong className="text-white">Category:</strong> {previewItem.category_id}</p>
              <p><strong className="text-white">Tags:</strong> {previewItem.tags?.join(', ')}</p>
            </div>

            <div className="flex justify-end space-x-3 pt-3 border-t border-white/10">
              <button
                onClick={() => handleOpenRejectModal(previewItem)}
                className="px-4 py-2 rounded-xl text-xs font-bold bg-[#FF007F]/20 text-[#FF007F] border border-[#FF007F] hover:bg-[#FF007F] hover:text-white transition-all cursor-pointer"
              >
                Reject Wallpaper
              </button>
              <button
                onClick={() => { handleApprove(previewItem.id); setPreviewItem(null); }}
                className="px-5 py-2 rounded-xl text-xs font-bold bg-[#00FF87] text-black font-extrabold hover:shadow-[0_0_15px_rgba(0,255,135,0.6)] cursor-pointer"
              >
                Approve & Move to Live
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Rejection Reason Modal */}
      {rejectModalItem && (
        <div className="fixed inset-0 z-50 bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
          <div className="liquid-glass max-w-lg w-full p-6 space-y-4 border-[#FF007F] glow-pink animate-in fade-in zoom-in duration-200">
            {/* Modal Header */}
            <div className="flex justify-between items-center border-b border-white/10 pb-3">
              <h3 className="font-orbitron font-bold text-lg text-white flex items-center gap-2">
                <AlertCircle className="w-5 h-5 text-[#FF007F]" /> Reject Submission
              </h3>
              <button
                onClick={() => { setRejectModalItem(null); setRejectReason(''); }}
                className="text-white/60 hover:text-white cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Target Item Summary */}
            {!isBulkReject && (
              <div className="flex items-center space-x-3 p-3 bg-black/40 rounded-xl border border-white/10">
                <img
                  src={rejectModalItem.thumbnail_url || rejectModalItem.image_url}
                  alt={rejectModalItem.title}
                  className="w-12 h-12 object-cover rounded-lg border border-white/20 flex-shrink-0"
                />
                <div className="min-w-0">
                  <h4 className="font-bold text-white text-sm truncate">{rejectModalItem.title}</h4>
                  <p className="text-xs text-[#8E95B3]">Creator: <span className="text-[#00E5FF]">{rejectModalItem.uploader_name}</span></p>
                </div>
              </div>
            )}

            {isBulkReject && (
              <div className="p-3 bg-black/40 rounded-xl border border-[#FF007F]/40 text-sm text-white">
                Rejecting <strong className="text-[#FF007F]">{selectedIds.length}</strong> selected wallpapers. The reason below will be sent to all respective creators.
              </div>
            )}

            {/* Quick Reason Presets */}
            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-[#8E95B3]">Select a Common Reason or Type Below:</label>
              <div className="flex flex-wrap gap-1.5">
                {REJECTION_PRESETS.map((preset, idx) => (
                  <button
                    key={idx}
                    type="button"
                    onClick={() => setRejectReason(preset)}
                    className={`text-[11px] px-2.5 py-1 rounded-lg border text-left transition-all cursor-pointer ${
                      rejectReason === preset
                        ? 'bg-[#FF007F] text-white border-[#FF007F]'
                        : 'bg-white/5 border-white/10 text-white/80 hover:border-[#FF007F]/60 hover:text-white'
                    }`}
                  >
                    {preset}
                  </button>
                ))}
              </div>
            </div>

            {/* Reason Textarea */}
            <div className="space-y-1.5">
              <label className="text-xs font-bold text-white flex items-center justify-between">
                <span>Detailed Rejection Reason:</span>
                <span className="text-[10px] text-[#8E95B3]">Visible on Creator's phone</span>
              </label>
              <textarea
                value={rejectReason}
                onChange={e => setRejectReason(e.target.value)}
                rows={4}
                placeholder="Enter specific feedback explaining why this wallpaper was rejected and how the creator can fix it..."
                className="w-full bg-black/60 border border-white/20 focus:border-[#FF007F] focus:ring-1 focus:ring-[#FF007F] rounded-xl p-3 text-sm text-white placeholder-white/30 resize-none outline-none transition-all"
              />
            </div>

            {/* Modal Actions */}
            <div className="flex justify-end space-x-3 pt-3 border-t border-white/10">
              <button
                type="button"
                onClick={() => { setRejectModalItem(null); setRejectReason(''); }}
                className="px-4 py-2 rounded-xl text-xs font-semibold bg-white/5 hover:bg-white/10 text-white transition-all cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleConfirmReject}
                disabled={!rejectReason.trim()}
                className={`px-5 py-2 rounded-xl text-xs font-bold flex items-center gap-1.5 transition-all ${
                  rejectReason.trim()
                    ? 'bg-[#FF007F] text-white hover:shadow-[0_0_15px_rgba(255,0,127,0.6)] cursor-pointer'
                    : 'bg-white/10 text-white/30 cursor-not-allowed'
                }`}
              >
                <X className="w-4 h-4" /> Confirm Rejection
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
