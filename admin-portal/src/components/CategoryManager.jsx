import React, { useState, useEffect } from 'react';
import { db, collection, getDocs, doc, setDoc, deleteDoc, updateDoc } from '../firebase';
import { Plus, Trash2, Edit2, Check, X, ArrowUpDown, ToggleLeft, ToggleRight, Sparkles } from 'lucide-react';

const INITIAL_CATEGORIES = [
  { id: 'cyberpunk', name: 'Cyberpunk', thumbnail_url: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?auto=format&fit=crop&w=300&q=80', sort_order: 1, is_active: true },
  { id: 'anime', name: 'Anime Neon', thumbnail_url: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?auto=format&fit=crop&w=300&q=80', sort_order: 2, is_active: true },
  { id: 'amoled', name: 'Dark AMOLED', thumbnail_url: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?auto=format&fit=crop&w=300&q=80', sort_order: 3, is_active: true },
  { id: 'liquid', name: 'Liquid Glass', thumbnail_url: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=300&q=80', sort_order: 4, is_active: true },
  { id: 'space', name: 'Deep Cosmos', thumbnail_url: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=300&q=80', sort_order: 5, is_active: true },
  { id: 'synthwave', name: 'Synthwave 80s', thumbnail_url: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&w=300&q=80', sort_order: 6, is_active: true }
];

export default function CategoryManager() {
  const [categories, setCategories] = useState(INITIAL_CATEGORIES);
  const [showAddModal, setShowAddModal] = useState(false);
  const [newCat, setNewCat] = useState({ id: '', name: '', thumbnail_url: '', sort_order: 7, is_active: true });
  const [notification, setNotification] = useState('');

  useEffect(() => {
    fetchCategories();
  }, []);

  const fetchCategories = async () => {
    try {
      const snap = await getDocs(collection(db, 'Categories'));
      if (!snap.empty) {
        const fetched = snap.docs.map(d => ({ id: d.id, ...d.data() }));
        fetched.sort((a, b) => a.sort_order - b.sort_order);
        setCategories(fetched);
      }
    } catch (_) {}
  };

  const notify = (msg) => {
    setNotification(msg);
    setTimeout(() => setNotification(''), 3000);
  };

  const handleToggleActive = async (id, currentVal) => {
    const nextVal = !currentVal;
    try {
      await updateDoc(doc(db, 'Categories', id), { is_active: nextVal });
    } catch (_) {}
    setCategories(prev =>
      prev.map(c => c.id === id ? { ...c, is_active: nextVal } : c)
    );
    notify(`Category ${id} active status updated!`);
  };

  const handleUpdateSortOrder = async (id, newOrder) => {
    const orderNum = parseInt(newOrder, 10) || 1;
    try {
      await updateDoc(doc(db, 'Categories', id), { sort_order: orderNum });
    } catch (_) {}
    setCategories(prev => {
      const updated = prev.map(c => c.id === id ? { ...c, sort_order: orderNum } : c);
      updated.sort((a, b) => a.sort_order - b.sort_order);
      return updated;
    });
    notify(`Sort order updated!`);
  };

  const handleDelete = async (id) => {
    if (!window.confirm(`Are you sure you want to delete category "${id}"?`)) return;
    try {
      await deleteDoc(doc(db, 'Categories', id));
    } catch (_) {}
    setCategories(prev => prev.filter(c => c.id !== id));
    notify(`Category "${id}" deleted.`);
  };

  const handleCreateCategory = async (e) => {
    e.preventDefault();
    if (!newCat.name) return;
    const catId = newCat.id ? newCat.id.toLowerCase().trim() : newCat.name.toLowerCase().replace(/\s+/g, '_');

    const item = {
      ...newCat,
      id: catId,
      sort_order: Number(newCat.sort_order) || 1
    };

    try {
      await setDoc(doc(db, 'Categories', catId), item);
    } catch (_) {}

    setCategories(prev => {
      const updated = [...prev.filter(c => c.id !== catId), item];
      updated.sort((a, b) => a.sort_order - b.sort_order);
      return updated;
    });

    setShowAddModal(false);
    setNewCat({ id: '', name: '', thumbnail_url: '', sort_order: categories.length + 1, is_active: true });
    notify(`Category "${item.name}" added successfully!`);
  };

  return (
    <div className="space-y-6">
      {notification && (
        <div className="liquid-glass border-[#00E5FF] p-4 text-[#00E5FF] flex items-center space-x-3 glow-cyan animate-pulse">
          <Sparkles className="w-5 h-5 flex-shrink-0" />
          <span className="font-semibold text-sm">{notification}</span>
        </div>
      )}

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold font-orbitron text-white tracking-wide">
            CATEGORY MANAGER
          </h2>
          <p className="text-[#8E95B3] text-sm mt-1">Configure mobile app category tabs, thumbnail banners, and display order.</p>
        </div>
        <button
          onClick={() => setShowAddModal(true)}
          className="px-4 py-2.5 rounded-xl text-xs font-bold bg-[#00E5FF] text-black hover:shadow-[0_0_15px_rgba(0,229,255,0.6)] flex items-center gap-2 cursor-pointer transition-all self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" /> Add Category
        </button>
      </div>

      {/* CRUD Table */}
      <div className="liquid-glass overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm">
            <thead className="bg-[#12121E] text-xs uppercase tracking-wider text-[#8E95B3] border-b border-white/10">
              <tr>
                <th className="py-4 px-6">Preview</th>
                <th className="py-4 px-6">Category ID</th>
                <th className="py-4 px-6">Display Name</th>
                <th className="py-4 px-6">Sort Order</th>
                <th className="py-4 px-6">Active</th>
                <th className="py-4 px-6 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/5">
              {categories.map((c) => (
                <tr key={c.id} className="hover:bg-white/[0.02] transition-colors">
                  <td className="py-3 px-6">
                    <img
                      src={c.thumbnail_url || 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?auto=format&fit=crop&w=150&q=80'}
                      alt={c.name}
                      className="w-12 h-12 rounded-lg object-cover border border-white/10"
                    />
                  </td>
                  <td className="py-3 px-6 font-mono text-xs text-[#00E5FF] font-semibold">{c.id}</td>
                  <td className="py-3 px-6 font-bold text-white">{c.name}</td>
                  <td className="py-3 px-6">
                    <input
                      type="number"
                      defaultValue={c.sort_order}
                      onBlur={(e) => handleUpdateSortOrder(c.id, e.target.value)}
                      className="w-16 px-2.5 py-1 rounded-lg bg-[#12121E] border border-white/20 text-white text-center text-xs focus:border-[#00E5FF] outline-none"
                    />
                  </td>
                  <td className="py-3 px-6">
                    <button
                      onClick={() => handleToggleActive(c.id, c.is_active)}
                      className="cursor-pointer text-white flex items-center"
                    >
                      {c.is_active ? (
                        <span className="flex items-center gap-1.5 text-xs text-[#00FF87] font-semibold">
                          <span className="w-2 h-2 rounded-full bg-[#00FF87] animate-pulse"></span> Active
                        </span>
                      ) : (
                        <span className="flex items-center gap-1.5 text-xs text-white/40 font-semibold">
                          <span className="w-2 h-2 rounded-full bg-white/30"></span> Hidden
                        </span>
                      )}
                    </button>
                  </td>
                  <td className="py-3 px-6 text-right">
                    <button
                      onClick={() => handleDelete(c.id)}
                      className="p-2 rounded-lg text-[#FF007F] hover:bg-[#FF007F]/20 transition-colors"
                      title="Delete Category"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Add Category Modal */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="liquid-glass max-w-md w-full p-6 space-y-4 border-[#00E5FF]">
            <div className="flex justify-between items-center border-b border-white/10 pb-3">
              <h3 className="font-orbitron font-bold text-white text-base">ADD NEW CATEGORY</h3>
              <button onClick={() => setShowAddModal(false)} className="text-white/60 hover:text-white">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateCategory} className="space-y-4">
              <div>
                <label className="block text-xs font-semibold text-[#8E95B3] mb-1">Display Name</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Mecha Cyber"
                  value={newCat.name}
                  onChange={(e) => setNewCat({ ...newCat, name: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#12121E] border border-white/20 text-white text-sm outline-none focus:border-[#00E5FF]"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-[#8E95B3] mb-1">Category ID (Optional Slug)</label>
                <input
                  type="text"
                  placeholder="e.g. mecha_cyber"
                  value={newCat.id}
                  onChange={(e) => setNewCat({ ...newCat, id: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#12121E] border border-white/20 text-white text-sm outline-none focus:border-[#00E5FF]"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-[#8E95B3] mb-1">Banner Thumbnail URL</label>
                <input
                  type="url"
                  placeholder="https://images.unsplash.com/..."
                  value={newCat.thumbnail_url}
                  onChange={(e) => setNewCat({ ...newCat, thumbnail_url: e.target.value })}
                  className="w-full px-3.5 py-2.5 rounded-xl bg-[#12121E] border border-white/20 text-white text-sm outline-none focus:border-[#00E5FF]"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-[#8E95B3] mb-1">Sort Order</label>
                  <input
                    type="number"
                    value={newCat.sort_order}
                    onChange={(e) => setNewCat({ ...newCat, sort_order: e.target.value })}
                    className="w-full px-3.5 py-2.5 rounded-xl bg-[#12121E] border border-white/20 text-white text-sm outline-none focus:border-[#00E5FF]"
                  />
                </div>
                <div className="flex flex-col justify-end">
                  <label className="flex items-center space-x-2 cursor-pointer pb-2.5">
                    <input
                      type="checkbox"
                      checked={newCat.is_active}
                      onChange={(e) => setNewCat({ ...newCat, is_active: e.target.checked })}
                      className="rounded accent-[#00E5FF]"
                    />
                    <span className="text-xs font-semibold text-white">Active in App</span>
                  </label>
                </div>
              </div>

              <div className="pt-2 flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 text-xs font-semibold text-white/60 hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 rounded-xl text-xs font-bold bg-[#00E5FF] text-black hover:shadow-lg"
                >
                  Save Category
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
