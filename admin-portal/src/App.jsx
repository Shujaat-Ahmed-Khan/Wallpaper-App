import React, { useState } from 'react';
import { Layers, CheckSquare, FolderKanban, UploadCloud, Shield, Sparkles, Activity } from 'lucide-react';
import ModerationQueue from './components/ModerationQueue';
import CategoryManager from './components/CategoryManager';
import DirectAdminUploader from './components/DirectAdminUploader';

export default function App() {
  const [activeTab, setActiveTab] = useState('moderation');

  return (
    <div className="min-h-screen bg-[#0A0A10] text-[#F0F4FF] flex flex-col selection:bg-[#00E5FF] selection:text-black">
      {/* Top Glass Navbar */}
      <header className="sticky top-0 z-40 bg-[#0A0A10]/80 backdrop-blur-xl border-b border-white/10 px-6 py-4">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          {/* Brand */}
          <div className="flex items-center space-x-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-[#00E5FF] to-[#FF007F] p-[1.5px] glow-cyan">
              <div className="w-full h-full bg-[#12121E] rounded-[10px] flex items-center justify-center">
                <Layers className="w-5 h-5 text-[#00E5FF]" />
              </div>
            </div>
            <div>
              <div className="flex items-center gap-1.5 font-orbitron font-black text-xl tracking-wider">
                <span className="text-[#00E5FF] drop-shadow-[0_0_10px_rgba(0,229,255,0.8)]">NEON</span>
                <span className="text-[#FF007F] drop-shadow-[0_0_10px_rgba(255,0,127,0.8)]">GLASS</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="text-[10px] text-[#8E95B3] font-semibold tracking-widest uppercase">Admin CMS Portal</span>
                <span className="text-[9px] px-1.5 py-0.5 rounded bg-[#00FF87]/20 text-[#00FF87] border border-[#00FF87]/40 font-mono">v1.0.0</span>
              </div>
            </div>
          </div>

          {/* Navigation Tabs */}
          <nav className="flex items-center space-x-2 bg-[#12121E] p-1.5 rounded-2xl border border-white/10">
            <button
              onClick={() => setActiveTab('moderation')}
              className={`px-4 py-2 rounded-xl text-xs font-bold tracking-wide transition-all flex items-center gap-2 cursor-pointer ${
                activeTab === 'moderation'
                  ? 'bg-[#00E5FF] text-black shadow-[0_0_15px_rgba(0,229,255,0.5)]'
                  : 'text-[#8E95B3] hover:text-white'
              }`}
            >
              <CheckSquare className="w-4 h-4" /> Moderation Queue
            </button>

            <button
              onClick={() => setActiveTab('categories')}
              className={`px-4 py-2 rounded-xl text-xs font-bold tracking-wide transition-all flex items-center gap-2 cursor-pointer ${
                activeTab === 'categories'
                  ? 'bg-[#FF007F] text-white shadow-[0_0_15px_rgba(255,0,127,0.5)]'
                  : 'text-[#8E95B3] hover:text-white'
              }`}
            >
              <FolderKanban className="w-4 h-4" /> Category Manager
            </button>

            <button
              onClick={() => setActiveTab('uploader')}
              className={`px-4 py-2 rounded-xl text-xs font-bold tracking-wide transition-all flex items-center gap-2 cursor-pointer ${
                activeTab === 'uploader'
                  ? 'bg-[#00FF87] text-black shadow-[0_0_15px_rgba(0,255,135,0.5)]'
                  : 'text-[#8E95B3] hover:text-white'
              }`}
            >
              <UploadCloud className="w-4 h-4" /> Direct Uploader
            </button>
          </nav>
        </div>
      </header>

      {/* Main Content View */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-6 md:p-8">
        {activeTab === 'moderation' && <ModerationQueue />}
        {activeTab === 'categories' && <CategoryManager />}
        {activeTab === 'uploader' && <DirectAdminUploader />}
      </main>

      {/* Bottom Status Bar */}
      <footer className="border-t border-white/10 py-4 px-6 bg-[#0A0A10]/90 text-xs text-[#8E95B3]">
        <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-3">
          <div className="flex items-center space-x-4">
            <span className="flex items-center gap-1.5 text-[#00FF87]">
              <span className="w-2 h-2 rounded-full bg-[#00FF87] animate-pulse"></span>
              Firestore & Storage Connected
            </span>
            <span className="hidden sm:inline text-white/20">|</span>
            <span className="flex items-center gap-1.5">
              <Activity className="w-3.5 h-3.5 text-[#00E5FF]" />
              Android Gyro Engine: 60 FPS Low-Pass Active
            </span>
          </div>
          <div>
            <span>Cross-Platform NeonGlass Architecture &copy; 2026 Bitrops</span>
          </div>
        </div>
      </footer>
    </div>
  );
}
