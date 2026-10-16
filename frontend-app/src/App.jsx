import React, { useState } from 'react';
import { 
  ShoppingBag, Heart, Search, Menu, X, Star, Plus, Minus, 
  ChevronRight, Check, ShieldCheck, Truck, Clock, Sparkles, 
  ArrowRight, Filter, Globe, Share2, MessageSquare, Phone, Mail, MapPin 
} from 'lucide-react';

// --- DATA ---
const categories = [
  { id: 'all', name: 'All Flowers' },
  { id: 'roses', name: 'Roses' },
  { id: 'tulips', name: 'Tulips' },
  { id: 'orchids', name: 'Orchids' },
  { id: 'seasonal', name: 'Seasonal Picks' },
  { id: 'bundles', name: 'Gift Bundles' },
];

const flowers = [
  {
    id: 1,
    name: 'Velvet Sunset Rose Bouquet',
    category: 'roses',
    price: 64.99,
    rating: 4.9,
    reviews: 128,
    image: 'https://images.unsplash.com/photo-1561181286-d3fee7d55364?auto=format&fit=crop&q=80&w=800',
    description: 'Rich crimson and warm peach roses hand-tied with seeded eucalyptus.'
  },
  {
    id: 2,
    name: 'Blushing Spring Tulip Medley',
    category: 'tulips',
    price: 45.00,
    rating: 4.8,
    reviews: 94,
    image: 'https://images.unsplash.com/photo-1520763185298-1b434c919102?auto=format&fit=crop&q=80&w=800',
    description: 'Fresh Dutch tulips in soft pastel pinks and cheerful yellows.'
  },
  {
    id: 3,
    name: 'Ethereal White Orchid',
    category: 'orchids',
    price: 78.50,
    rating: 5.0,
    reviews: 62,
    image: 'https://images.unsplash.com/photo-1521334884684-d80222895322?auto=format&fit=crop&q=80&w=800',
    description: 'Pristine potted Phalaenopsis orchid in a modern ceramic planter.'
  },
  {
    id: 4,
    name: 'Golden Sunflower & Daisy Charm',
    category: 'seasonal',
    price: 52.00,
    rating: 4.7,
    reviews: 81,
    image: 'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?auto=format&fit=crop&q=80&w=800',
    description: 'Bright sunflowers paired with wild daisies to instantly warm up any room.'
  },
  {
    id: 5,
    name: 'Lavish Romance Luxury Bundle',
    category: 'bundles',
    price: 120.00,
    rating: 4.9,
    reviews: 215,
    image: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&q=80&w=800',
    description: 'Two dozen premium red roses accompanied by artisan dark chocolate and soy candle.'
  },
  {
    id: 6,
    name: 'Lavender Dream Hydrangea',
    category: 'seasonal',
    price: 58.00,
    rating: 4.8,
    reviews: 73,
    image: 'https://images.unsplash.com/photo-1508784411985-c424d0cfef8f?auto=format&fit=crop&q=80&w=800',
    description: 'Lush blue and purple hydrangeas designed with delicate baby’s breath.'
  }
];

const careTips = [
  {
    title: 'Trim Stems at an Angle',
    summary: 'Cut 1-2 inches off your stems at a 45-degree angle before placing them in water to maximize hydration.',
    detail: 'Cutting at an angle prevents stems from sitting flat against the bottom of the vase, which allows them to freely absorb water and nutrients.'
  },
  {
    title: 'Change Water Every 2 Days',
    summary: 'Keep your arrangement fresh by emptying old water, rinsing the vase, and refilling with cool clean water.',
    detail: 'Bacteria builds up quickly in stagnant flower water. Replacing it regularly extends the vase life of your blooms by up to a week.'
  },
  {
    title: 'Avoid Direct Sunlight & Heat',
    summary: 'Display your bouquet away from direct sunbeams, ripening fruit bowls, and heating vents.',
    detail: 'Heat and ethylene gas from ripening fruit accelerate the aging process, causing petals to wilt and drop prematurely.'
  }
];

export default function App() {
  const [activeTab, setActiveTab] = useState('home');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [cart, setCart] = useState([]);
  const [wishlist, setWishlist] = useState([]);
  const [isCartOpen, setIsCartOpen] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [checkoutComplete, setCheckoutComplete] = useState(false);

  // Bouquet Builder State with images added
  const [builderBase, setBuilderBase] = useState({ name: 'Roses', price: 35, image: 'https://images.unsplash.com/photo-1561181286-d3fee7d55364?auto=format&fit=crop&q=80&w=400' });
  const [builderGreenery, setBuilderGreenery] = useState({ name: 'Eucalyptus', price: 10, image: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&q=80&w=400' });
  const [builderWrapping, setBuilderWrapping] = useState({ name: 'Kraft Paper', price: 5, image: 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&q=80&w=400' });
  const [builderRibbon, setBuilderRibbon] = useState({ name: 'Silk Satin', price: 4, image: 'https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&q=80&w=400' });

  // Filter products
  const filteredFlowers = flowers.filter(flower => {
    const matchesCategory = selectedCategory === 'all' || flower.category === selectedCategory;
    const matchesSearch = flower.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
                          flower.description.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  const addToCart = (item) => {
    setCart(prev => {
      const existing = prev.find(p => p.id === item.id);
      if (existing) {
        return prev.map(p => p.id === item.id ? { ...p, quantity: p.quantity + 1 } : p);
      }
      return [...prev, { ...item, quantity: 1 }];
    });
    setIsCartOpen(true);
  };

  const updateQuantity = (id, delta) => {
    setCart(prev => prev.map(item => {
      if (item.id === id) {
        const newQty = item.quantity + delta;
        return newQty > 0 ? { ...item, quantity: newQty } : null;
      }
      return item;
    }).filter(Boolean));
  };

  const toggleWishlist = (id) => {
    setWishlist(prev => prev.includes(id) ? prev.filter(item => item !== id) : [...prev, id]);
  };

  const cartTotal = cart.reduce((sum, item) => sum + (item.price * item.quantity), 0);
  const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0);

  const handleCustomBouquetAdd = () => {
    const customItem = {
      id: `custom-${Date.now()}`,
      name: `Custom Bouquet (${builderBase.name} + ${builderGreenery.name})`,
      price: builderBase.price + builderGreenery.price + builderWrapping.price + builderRibbon.price,
      image: 'https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&q=80&w=800',
      quantity: 1
    };
    addToCart(customItem);
  };

  return (
    <div className="min-h-screen bg-[#FDFBF7] text-[#2C3531] font-sans selection:bg-[#E8DCC4]">
      
      {/* TOP NOTIFICATION BAR */}
      <div className="bg-[#5C7053] text-white text-xs sm:text-sm py-2 px-4 text-center tracking-wide font-medium flex items-center justify-center gap-2">
        <Sparkles className="w-4 h-4 animate-pulse" />
        <span>Free Same-Day Delivery on orders over $75 with code BLOOM2026</span>
      </div>

      {/* NAVIGATION BAR */}
      <header className="sticky top-0 z-40 bg-[#FDFBF7]/90 backdrop-blur-md border-b border-[#E8DCC4]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
          
          {/* Brand Logo */}
          <div className="flex items-center gap-2 cursor-pointer" onClick={() => setActiveTab('home')}>
            <div className="w-10 h-10 rounded-full bg-[#5C7053] flex items-center justify-center text-white font-serif text-xl shadow-md">
              B
            </div>
            <div>
              <span className="font-serif text-xl sm:text-2xl font-bold tracking-tight text-[#2C3531]">Botanical Blossom</span>
              <span className="block text-[10px] tracking-widest uppercase text-[#5C7053] font-semibold">Artisanal Florist</span>
            </div>
          </div>

          {/* Desktop Links */}
          <nav className="hidden md:flex items-center gap-8 font-medium text-sm">
            <button onClick={() => setActiveTab('home')} className={`transition-colors hover:text-[#5C7053] ${activeTab === 'home' ? 'text-[#5C7053] font-bold border-b-2 border-[#5C7053] pb-1' : 'text-[#6B7280]'}`}>Home</button>
            <button onClick={() => setActiveTab('catalog')} className={`transition-colors hover:text-[#5C7053] ${activeTab === 'catalog' ? 'text-[#5C7053] font-bold border-b-2 border-[#5C7053] pb-1' : 'text-[#6B7280]'}`}>Collection</button>
            <button onClick={() => setActiveTab('builder')} className={`transition-colors hover:text-[#5C7053] ${activeTab === 'builder' ? 'text-[#5C7053] font-bold border-b-2 border-[#5C7053] pb-1' : 'text-[#6B7280]'}`}>Bouquet Builder</button>
            <button onClick={() => setActiveTab('care')} className={`transition-colors hover:text-[#5C7053] ${activeTab === 'care' ? 'text-[#5C7053] font-bold border-b-2 border-[#5C7053] pb-1' : 'text-[#6B7280]'}`}>Care Guide</button>
            <button onClick={() => setActiveTab('about')} className={`transition-colors hover:text-[#5C7053] ${activeTab === 'about' ? 'text-[#5C7053] font-bold border-b-2 border-[#5C7053] pb-1' : 'text-[#6B7280]'}`}>About Us</button>
          </nav>

          {/* Action Icons */}
          <div className="flex items-center gap-4">
            <button 
              onClick={() => setActiveTab('catalog')} 
              className="p-2 text-[#2C3531] hover:text-[#5C7053] transition-colors relative"
              title="Wishlist"
            >
              <Heart className={`w-6 h-6 ${wishlist.length > 0 ? 'fill-[#C86D51] text-[#C86D51]' : ''}`} />
              {wishlist.length > 0 && (
                <span className="absolute -top-1 -right-1 bg-[#C86D51] text-white text-[10px] w-4 h-4 rounded-full flex items-center justify-center font-bold">
                  {wishlist.length}
                </span>
              )}
            </button>

            <button 
              onClick={() => setIsCartOpen(true)}
              className="p-2 bg-[#5C7053] text-white rounded-full hover:bg-[#4A5B42] transition-colors relative shadow-md flex items-center gap-2 px-4"
            >
              <ShoppingBag className="w-5 h-5" />
              <span className="text-sm font-semibold">{cartCount}</span>
            </button>

            {/* Mobile menu button */}
            <button 
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden p-2 text-[#2C3531]"
            >
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Mobile Nav Menu */}
        {mobileMenuOpen && (
          <div className="md:hidden bg-[#FDFBF7] border-b border-[#E8DCC4] px-4 pt-2 pb-6 space-y-3">
            <button onClick={() => { setActiveTab('home'); setMobileMenuOpen(false); }} className="block w-full text-left py-2 font-medium text-[#2C3531]">Home</button>
            <button onClick={() => { setActiveTab('catalog'); setMobileMenuOpen(false); }} className="block w-full text-left py-2 font-medium text-[#2C3531]">Collection</button>
            <button onClick={() => { setActiveTab('builder'); setMobileMenuOpen(false); }} className="block w-full text-left py-2 font-medium text-[#2C3531]">Bouquet Builder</button>
            <button onClick={() => { setActiveTab('care'); setMobileMenuOpen(false); }} className="block w-full text-left py-2 font-medium text-[#2C3531]">Care Guide</button>
            <button onClick={() => { setActiveTab('about'); setMobileMenuOpen(false); }} className="block w-full text-left py-2 font-medium text-[#2C3531]">About Us</button>
          </div>
        )}
      </header>

      {/* MAIN CONTENT VIEWS */}
      <main>
        
        {/* VIEW: HOME */}
        {activeTab === 'home' && (
          <div>
            {/* HERO SECTION */}
            <section className="relative overflow-hidden bg-gradient-to-b from-[#F3EEE3] to-[#FDFBF7] py-16 sm:py-24">
              <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
                <div className="space-y-6">
                  <span className="inline-block bg-[#E8DCC4]/60 text-[#5C7053] px-3 py-1 rounded-full text-xs font-semibold tracking-wider uppercase">
                    Handcrafted Daily with Love
                  </span>
                  <h1 className="font-serif text-4xl sm:text-6xl font-bold tracking-tight text-[#2C3531] leading-tight">
                    Express Your Feelings Through <span className="italic text-[#5C7053]">Fresh Blooms</span>
                  </h1>
                  <p className="text-gray-600 text-base sm:text-lg max-w-lg">
                    Discover hand-arranged bouquets crafted by master floral designers using sustainably sourced, farm-fresh flowers delivered right to your door.
                  </p>
                  <div className="flex flex-col sm:flex-row gap-4 pt-2">
                    <button 
                      onClick={() => setActiveTab('catalog')}
                      className="bg-[#5C7053] hover:bg-[#4A5B42] text-white font-medium px-8 py-3.5 rounded-full shadow-lg transition-all flex items-center justify-center gap-2"
                    >
                      Shop Collection <ArrowRight className="w-4 h-4" />
                    </button>
                    <button 
                      onClick={() => setActiveTab('builder')}
                      className="bg-transparent hover:bg-[#E8DCC4]/30 text-[#2C3531] border border-[#5C7053] font-medium px-8 py-3.5 rounded-full transition-all flex items-center justify-center gap-2"
                    >
                      Build Custom Bouquet
                    </button>
                  </div>

                  {/* Trust Metrics */}
                  <div className="grid grid-cols-3 gap-4 pt-8 border-t border-[#E8DCC4]/60">
                    <div>
                      <p className="font-serif text-2xl font-bold text-[#5C7053]">100%</p>
                      <p className="text-xs text-gray-500">Farm Fresh Guarantee</p>
                    </div>
                    <div>
                      <p className="font-serif text-2xl font-bold text-[#5C7053]">Same Day</p>
                      <p className="text-xs text-gray-500">Express Delivery</p>
                    </div>
                    <div>
                      <p className="font-serif text-2xl font-bold text-[#5C7053]">4.9 / 5</p>
                      <p className="text-xs text-gray-500">Over 5,000 Reviews</p>
                    </div>
                  </div>
                </div>

                <div className="relative">
                  <div className="relative mx-auto w-full max-w-md rounded-3xl overflow-hidden shadow-2xl border-4 border-white">
                    <img 
                      src="https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&q=80&w=800" 
                      alt="Luxurious Bouquet" 
                      className="w-full h-[450px] object-cover hover:scale-105 transition-transform duration-700"
                    />
                  </div>
                  <div className="absolute -bottom-6 -left-6 bg-white p-4 rounded-2xl shadow-xl border border-[#E8DCC4] flex items-center gap-3">
                    <div className="w-12 h-12 rounded-full bg-[#E8DCC4] flex items-center justify-center text-[#5C7053]">
                      <Sparkles className="w-6 h-6" />
                    </div>
                    <div>
                      <p className="text-xs text-gray-500">Design of the Week</p>
                      <p className="font-serif font-bold text-sm text-[#2C3531]">Sunset Glow Arrangement</p>
                    </div>
                  </div>
                </div>
              </div>
            </section>

            {/* FEATURED CATEGORIES PREVIEW */}
            <section className="py-16 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <div className="flex justify-between items-end mb-10">
                <div>
                  <span className="text-xs uppercase tracking-widest text-[#5C7053] font-semibold">Collections</span>
                  <h2 className="font-serif text-3xl font-bold text-[#2C3531]">Shop by Occasion & Type</h2>
                </div>
                <button 
                  onClick={() => setActiveTab('catalog')} 
                  className="text-sm font-semibold text-[#5C7053] hover:underline flex items-center gap-1"
                >
                  View All Collection <ChevronRight className="w-4 h-4" />
                </button>
              </div>

              <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
                {[
                  { name: 'Romantic Roses', image: 'https://images.unsplash.com/photo-1559563362-c667ba5f5480?auto=format&fit=crop&q=80&w=600', cat: 'roses' },
                  { name: 'Cheerful Tulips', image: 'https://images.unsplash.com/photo-1520763185298-1b434c919102?auto=format&fit=crop&q=80&w=600', cat: 'tulips' },
                  { name: 'Exotic Orchids', image: 'https://images.unsplash.com/photo-1521334884684-d80222895322?auto=format&fit=crop&q=80&w=600', cat: 'orchids' },
                  { name: 'Gift Bundles', image: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&q=80&w=600', cat: 'bundles' }
                ].map((item, idx) => (
                  <div 
                    key={idx}
                    onClick={() => { setSelectedCategory(item.cat); setActiveTab('catalog'); }}
                    className="group relative rounded-2xl overflow-hidden shadow-md cursor-pointer h-72"
                  >
                    <img src={item.image} alt={item.name} className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent flex flex-col justify-end p-6 text-white">
                      <h3 className="font-serif text-lg font-bold">{item.name}</h3>
                      <span className="text-xs text-gray-200 mt-1 flex items-center gap-1 group-hover:translate-x-1 transition-transform">
                        Explore <ChevronRight className="w-3 h-3" />
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </section>
          </div>
        )}

        {/* VIEW: CATALOG */}
        {activeTab === 'catalog' && (
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
            <div className="text-center max-w-2xl mx-auto mb-10">
              <span className="text-xs uppercase tracking-widest text-[#5C7053] font-semibold">Hand-Curated Catalog</span>
              <h1 className="font-serif text-4xl font-bold text-[#2C3531] mt-2">Explore Our Fresh Flower Selection</h1>
              <p className="text-gray-600 mt-2">Find the ultimate bouquet to brighten someone's day or elevate your home decor.</p>
            </div>

            {/* Search & Filter Bar */}
            <div className="flex flex-col md:flex-row gap-4 items-center justify-between mb-8">
              {/* Category Pills */}
              <div className="flex flex-wrap gap-2 justify-center md:justify-start">
                {categories.map(cat => (
                  <button
                    key={cat.id}
                    onClick={() => setSelectedCategory(cat.id)}
                    className={`px-4 py-2 rounded-full text-sm font-medium transition-all ${selectedCategory === cat.id ? 'bg-[#5C7053] text-white shadow-md' : 'bg-white text-[#2C3531] border border-[#E8DCC4] hover:bg-[#E8DCC4]/30'}`}
                  >
                    {cat.name}
                  </button>
                ))}
              </div>

              {/* Search Box */}
              <div className="relative w-full md:w-72">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input 
                  type="text" 
                  placeholder="Search flowers..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full bg-white pl-10 pr-4 py-2 rounded-full border border-[#E8DCC4] text-sm focus:outline-none focus:ring-2 focus:ring-[#5C7053]"
                />
              </div>
            </div>

            {/* Product Grid */}
            {filteredFlowers.length === 0 ? (
              <div className="text-center py-20 bg-white rounded-2xl border border-[#E8DCC4]">
                <p className="font-serif text-xl text-gray-600">No flowers found matching your search.</p>
                <button onClick={() => { setSearchQuery(''); setSelectedCategory('all'); }} className="mt-4 text-[#5C7053] font-semibold underline">Reset filters</button>
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8">
                {filteredFlowers.map(flower => (
                  <div key={flower.id} className="bg-white rounded-2xl overflow-hidden shadow-sm hover:shadow-xl transition-all border border-[#E8DCC4]/60 flex flex-col">
                    <div className="relative h-64 overflow-hidden group">
                      <img src={flower.image} alt={flower.name} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" />
                      <button 
                        onClick={() => toggleWishlist(flower.id)}
                        className="absolute top-4 right-4 p-2.5 rounded-full bg-white/80 backdrop-blur-md hover:bg-white transition-colors shadow"
                      >
                        <Heart className={`w-5 h-5 ${wishlist.includes(flower.id) ? 'fill-[#C86D51] text-[#C86D51]' : 'text-gray-600'}`} />
                      </button>
                      <span className="absolute bottom-4 left-4 bg-white/90 backdrop-blur-md px-3 py-1 rounded-full text-xs font-semibold text-[#5C7053]">
                        ${flower.price.toFixed(2)}
                      </span>
                    </div>

                    <div className="p-6 flex flex-col flex-grow justify-between">
                      <div>
                        <div className="flex items-center gap-1 text-amber-500 text-xs font-semibold mb-1">
                          <Star className="w-4 h-4 fill-amber-400 text-amber-400" />
                          <span>{flower.rating}</span>
                          <span className="text-gray-400 font-normal">({flower.reviews} reviews)</span>
                        </div>
                        <h3 className="font-serif text-xl font-bold text-[#2C3531]">{flower.name}</h3>
                        <p className="text-gray-600 text-sm mt-2 line-clamp-2">{flower.description}</p>
                      </div>

                      <div className="mt-6 pt-4 border-t border-[#E8DCC4]/40 flex items-center justify-between">
                        <span className="text-xs font-medium text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-md">In Stock & Fresh</span>
                        <button 
                          onClick={() => addToCart(flower)}
                          className="bg-[#5C7053] hover:bg-[#4A5B42] text-white px-5 py-2.5 rounded-full text-sm font-medium transition-colors shadow-sm flex items-center gap-2"
                        >
                          <ShoppingBag className="w-4 h-4" /> Add to Cart
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}

        {/* VIEW: BOUQUET BUILDER */}
        {activeTab === 'builder' && (
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
            <div className="text-center max-w-2xl mx-auto mb-12">
              <span className="text-xs uppercase tracking-widest text-[#5C7053] font-semibold">Interactive Studio</span>
              <h1 className="font-serif text-4xl font-bold text-[#2C3531] mt-2">Build Your Custom Bouquet</h1>
              <p className="text-gray-600 mt-2">Design a personalized arrangement step-by-step for a special gift or custom centerpiece.</p>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-12 items-start">
              {/* Builder Controls */}
              <div className="lg:col-span-2 space-y-8 bg-white p-6 sm:p-8 rounded-3xl border border-[#E8DCC4] shadow-sm">
                
                {/* Step 1: Base Flowers */}
                <div>
                  <h3 className="font-serif text-lg font-bold text-[#2C3531] mb-3">1. Select Base Flowers</h3>
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                    {[
                      { name: 'Roses', price: 35, image: 'https://images.unsplash.com/photo-1561181286-d3fee7d55364?auto=format&fit=crop&q=80&w=400' },
                      { name: 'Tulips', price: 28, image: 'https://images.unsplash.com/photo-1520763185298-1b434c919102?auto=format&fit=crop&q=80&w=400' },
                      { name: 'Orchids', price: 45, image: 'https://images.unsplash.com/photo-1521334884684-d80222895322?auto=format&fit=crop&q=80&w=400' },
                    ].map(item => (
                      <div 
                        key={item.name}
                        onClick={() => setBuilderBase(item)}
                        className={`cursor-pointer rounded-2xl p-3 border-2 transition-all flex flex-col items-center text-center ${builderBase.name === item.name ? 'border-[#5C7053] bg-[#5C7053]/5 shadow-md' : 'border-[#E8DCC4] hover:border-gray-400'}`}
                      >
                        <img src={item.image} alt={item.name} className="w-16 h-16 rounded-xl object-cover mb-2" />
                        <span className="font-semibold text-sm">{item.name}</span>
                        <span className="text-xs text-[#5C7053] font-medium">+${item.price}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Step 2: Greenery (Now with Images!) */}
                <div>
                  <h3 className="font-serif text-lg font-bold text-[#2C3531] mb-3">2. Choose Greenery & Filler</h3>
                  <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                    {[
                      { name: 'Eucalyptus', price: 10, image: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?auto=format&fit=crop&q=80&w=400' },
                      { name: 'Baby Breath', price: 8, image: 'https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&q=80&w=800' },
                      { name: 'Fern Mix', price: 12, image: 'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?auto=format&fit=crop&q=80&w=400' },
                    ].map(item => (
                      <div 
                        key={item.name}
                        onClick={() => setBuilderGreenery(item)}
                        className={`cursor-pointer rounded-2xl p-3 border-2 transition-all flex flex-col items-center text-center ${builderGreenery.name === item.name ? 'border-[#5C7053] bg-[#5C7053]/5 shadow-md' : 'border-[#E8DCC4]'}`}
                      >
                        <img src={item.image} alt={item.name} className="w-16 h-16 rounded-xl object-cover mb-2" />
                        <span className="font-semibold text-sm">{item.name}</span>
                        <span className="text-xs text-[#5C7053] font-medium">+${item.price}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Step 3: Wrapping Paper (Now with Images!) */}
                <div>
                  <h3 className="font-serif text-lg font-bold text-[#2C3531] mb-3">3. Wrapping Style</h3>
                  <div className="grid grid-cols-3 gap-4">
                    {[
                      { name: 'Kraft Paper', price: 5, image: 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&q=80&w=400' },
                      { name: 'French Linen', price: 12, image: 'https://images.unsplash.com/photo-1582562124811-c09040d0a901?auto=format&fit=crop&q=80&w=400' },
                      { name: 'Matte Pastel', price: 7, image: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?auto=format&fit=crop&q=80&w=400' },
                    ].map(item => (
                      <div 
                        key={item.name}
                        onClick={() => setBuilderWrapping(item)}
                        className={`cursor-pointer rounded-2xl p-3 border-2 transition-all flex flex-col items-center text-center ${builderWrapping.name === item.name ? 'border-[#5C7053] bg-[#5C7053]/5 shadow-md' : 'border-[#E8DCC4]'}`}
                      >
                        <img src={item.image} alt={item.name} className="w-16 h-16 rounded-xl object-cover mb-2" />
                        <span className="font-semibold text-sm">{item.name}</span>
                        <span className="text-xs text-[#5C7053] font-medium">+${item.price}</span>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Step 4: Ribbon (Now with Images!) */}
                <div>
                  <h3 className="font-serif text-lg font-bold text-[#2C3531] mb-3">4. Ribbon Bow</h3>
                  <div className="grid grid-cols-3 gap-4">
                    {[
                      { name: 'Silk Satin', price: 4, image: 'https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&q=80&w=400' },
                      { name: 'Velvet Ribbon', price: 6, image: 'https://images.unsplash.com/photo-1606800052052-a08af7148866?auto=format&fit=crop&q=80&w=400' },
                      { name: 'Jute Twine', price: 3, image: 'https://images.unsplash.com/photo-1550989460-0adf9ea622e2?auto=format&fit=crop&q=80&w=400' },
                    ].map(item => (
                      <div 
                        key={item.name}
                        onClick={() => setBuilderRibbon(item)}
                        className={`cursor-pointer rounded-2xl p-3 border-2 transition-all flex flex-col items-center text-center ${builderRibbon.name === item.name ? 'border-[#5C7053] bg-[#5C7053]/5 shadow-md' : 'border-[#E8DCC4]'}`}
                      >
                        <img src={item.image} alt={item.name} className="w-16 h-16 rounded-xl object-cover mb-2" />
                        <span className="font-semibold text-sm">{item.name}</span>
                        <span className="text-xs text-[#5C7053] font-medium">+${item.price}</span>
                      </div>
                    ))}
                  </div>
                </div>

              </div>

              {/* Live Preview & Summary Card */}
              <div className="bg-white p-6 sm:p-8 rounded-3xl border border-[#E8DCC4] shadow-xl sticky top-28 space-y-6">
                <h3 className="font-serif text-xl font-bold text-[#2C3531] pb-3 border-b border-[#E8DCC4]">Your Custom Design</h3>
                
                <div className="relative h-48 rounded-2xl overflow-hidden bg-[#F3EEE3]">
                  <img src="https://images.unsplash.com/photo-1563245372-f21724e3856d?auto=format&fit=crop&q=80&w=600" alt="Custom Bouquet" className="w-full h-full object-cover" />
                  <div className="absolute inset-0 bg-black/20 flex items-end p-4">
                    <span className="bg-white/90 backdrop-blur-md px-3 py-1 rounded-full text-xs font-bold text-[#5C7053]">
                      Masterpiece Creation
                    </span>
                  </div>
                </div>

                <div className="space-y-3 text-sm">
                  <div className="flex justify-between">
                    <span className="text-gray-600">Base ({builderBase.name})</span>
                    <span className="font-semibold">${builderBase.price.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Greenery ({builderGreenery.name})</span>
                    <span className="font-semibold">${builderGreenery.price.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Wrapping ({builderWrapping.name})</span>
                    <span className="font-semibold">${builderWrapping.price.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-gray-600">Ribbon ({builderRibbon.name})</span>
                    <span className="font-semibold">${builderRibbon.price.toFixed(2)}</span>
                  </div>
                </div>

                <div className="pt-4 border-t border-[#E8DCC4] flex justify-between items-center">
                  <span className="font-serif font-bold text-lg">Total Price</span>
                  <span className="font-serif font-bold text-2xl text-[#5C7053]">
                    ${(builderBase.price + builderGreenery.price + builderWrapping.price + builderRibbon.price).toFixed(2)}
                  </span>
                </div>

                <button 
                  onClick={handleCustomBouquetAdd}
                  className="w-full bg-[#5C7053] hover:bg-[#4A5B42] text-white font-medium py-3.5 rounded-full shadow-md transition-all flex items-center justify-center gap-2"
                >
                  <ShoppingBag className="w-5 h-5" /> Add Custom Bouquet to Cart
                </button>
              </div>
            </div>
          </div>
        )}

        {/* VIEW: CARE GUIDE */}
        {activeTab === 'care' && (
          <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
            <div className="text-center mb-12">
              <span className="text-xs uppercase tracking-widest text-[#5C7053] font-semibold">Expert Knowledge</span>
              <h1 className="font-serif text-4xl font-bold text-[#2C3531] mt-2">Flower Care Guide</h1>
              <p className="text-gray-600 mt-2">Keep your arrangements fresh and vibrant for weeks with these pro maintenance steps.</p>
            </div>

            <div className="space-y-6">
              {careTips.map((tip, idx) => (
                <div key={idx} className="bg-white rounded-2xl p-6 sm:p-8 border border-[#E8DCC4] shadow-sm space-y-3">
                  <div className="flex items-center gap-3">
                    <span className="w-8 h-8 rounded-full bg-[#5C7053]/10 text-[#5C7053] flex items-center justify-center font-bold font-serif text-sm">
                      0{idx + 1}
                    </span>
                    <h3 className="font-serif text-xl font-bold text-[#2C3531]">{tip.title}</h3>
                  </div>
                  <p className="text-gray-700 font-medium pl-11">{tip.summary}</p>
                  <p className="text-gray-500 text-sm pl-11">{tip.detail}</p>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* VIEW: ABOUT US */}
        {activeTab === 'about' && (
          <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-12 space-y-12">
            <div className="text-center max-w-2xl mx-auto">
              <span className="text-xs uppercase tracking-widest text-[#5C7053] font-semibold">Our Story</span>
              <h1 className="font-serif text-4xl font-bold text-[#2C3531] mt-2">Rooted in Passion & Sustainability</h1>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-8 items-center">
              <div className="rounded-3xl overflow-hidden shadow-lg">
                <img src="https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&q=80&w=800" alt="Florist Workspace" className="w-full h-[400px] object-cover" />
              </div>
              <div className="space-y-4">
                <h3 className="font-serif text-2xl font-bold text-[#2C3531]">Bringing Nature Closer to Your Heart</h3>
                <p className="text-gray-600 leading-relaxed">
                  Founded in 2020, Botanical Blossom started with a simple belief: flowers have the unique power to transform emotions, brighten spaces, and create unforgettable memories.
                </p>
                <p className="text-gray-600 leading-relaxed">
                  We partner directly with eco-conscious local farms and international sustainable growers to ensure that every stem we deliver is exceptionally fresh, vibrant, and ethically harvested.
                </p>
                <div className="grid grid-cols-2 gap-4 pt-4">
                  <div className="border-l-2 border-[#5C7053] pl-4">
                    <p className="font-serif text-2xl font-bold text-[#5C7053]">15k+</p>
                    <p className="text-xs text-gray-500">Delivered Bouquets</p>
                  </div>
                  <div className="border-l-2 border-[#5C7053] pl-4">
                    <p className="font-serif text-2xl font-bold text-[#5C7053]">30+</p>
                    <p className="text-xs text-gray-500">Partner Eco-Farms</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

      </main>

      {/* CART DRAWER MODAL */}
      {isCartOpen && (
        <div className="fixed inset-0 z-50 overflow-hidden">
          <div className="absolute inset-0 bg-black/50 backdrop-blur-sm transition-opacity" onClick={() => setIsCartOpen(false)} />

          <div className="absolute inset-y-0 right-0 max-w-full flex">
            <div className="w-screen max-w-md bg-[#FDFBF7] shadow-2xl flex flex-col">
              
              {/* Header */}
              <div className="p-6 border-b border-[#E8DCC4] flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <ShoppingBag className="w-5 h-5 text-[#5C7053]" />
                  <h2 className="font-serif text-xl font-bold text-[#2C3531]">Your Shopping Bag</h2>
                </div>
                <button onClick={() => setIsCartOpen(false)} className="p-2 text-gray-400 hover:text-gray-600">
                  <X className="w-6 h-6" />
                </button>
              </div>

              {/* Cart Body */}
              <div className="flex-1 overflow-y-auto p-6 space-y-4">
                {checkoutComplete ? (
                  <div className="text-center py-20 space-y-4">
                    <div className="w-16 h-16 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto">
                      <Check className="w-8 h-8" />
                    </div>
                    <h3 className="font-serif text-2xl font-bold text-[#2C3531]">Order Placed Successfully!</h3>
                    <p className="text-gray-600 text-sm">Thank you for shopping with Botanical Blossom. Your fresh flowers are being prepared for delivery.</p>
                    <button 
                      onClick={() => { setCheckoutComplete(false); setCart([]); setIsCartOpen(false); setActiveTab('home'); }}
                      className="mt-4 bg-[#5C7053] text-white px-6 py-2.5 rounded-full text-sm font-medium"
                    >
                      Continue Shopping
                    </button>
                  </div>
                ) : cart.length === 0 ? (
                  <div className="text-center py-20 space-y-3">
                    <ShoppingBag className="w-12 h-12 text-gray-300 mx-auto" />
                    <p className="font-serif text-lg text-gray-500">Your bag is empty.</p>
                    <button onClick={() => { setIsCartOpen(false); setActiveTab('catalog'); }} className="text-[#5C7053] font-semibold text-sm underline">
                      Explore our collection
                    </button>
                  </div>
                ) : (
                  cart.map(item => (
                    <div key={item.id} className="flex gap-4 items-center bg-white p-4 rounded-2xl border border-[#E8DCC4]">
                      <img src={item.image} alt={item.name} className="w-16 h-16 rounded-xl object-cover" />
                      <div className="flex-1">
                        <h4 className="font-serif font-bold text-sm text-[#2C3531]">{item.name}</h4>
                        <p className="text-xs text-[#5C7053] font-semibold mt-1">${item.price.toFixed(2)}</p>
                        
                        <div className="flex items-center gap-3 mt-2">
                          <button onClick={() => updateQuantity(item.id, -1)} className="p-1 rounded-md bg-gray-100 hover:bg-gray-200">
                            <Minus className="w-3 h-3" />
                          </button>
                          <span className="text-xs font-semibold">{item.quantity}</span>
                          <button onClick={() => updateQuantity(item.id, 1)} className="p-1 rounded-md bg-gray-100 hover:bg-gray-200">
                            <Plus className="w-3 h-3" />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* Footer */}
              {!checkoutComplete && cart.length > 0 && (
                <div className="p-6 border-t border-[#E8DCC4] space-y-4 bg-white">
                  <div className="flex justify-between text-base font-semibold">
                    <span className="text-gray-600">Subtotal</span>
                    <span className="font-serif text-xl text-[#2C3531]">${cartTotal.toFixed(2)}</span>
                  </div>
                  <p className="text-xs text-gray-400">Shipping and taxes calculated during secure checkout.</p>
                  
                  <button 
                    onClick={() => setCheckoutComplete(true)}
                    className="w-full bg-[#5C7053] hover:bg-[#4A5B42] text-white py-3.5 rounded-full font-medium transition-colors shadow-md flex items-center justify-center gap-2"
                  >
                    Proceed to Secure Checkout <ArrowRight className="w-4 h-4" />
                  </button>
                </div>
              )}

            </div>
          </div>
        </div>
      )}

      {/* FOOTER */}
      <footer className="bg-[#2C3531] text-[#FDFBF7] pt-16 pb-12 border-t border-[#E8DCC4]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-1 md:grid-cols-4 gap-10 mb-12">
          
          <div className="space-y-4">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-[#5C7053] flex items-center justify-center text-white font-serif font-bold">
                B
              </div>
              <span className="font-serif text-xl font-bold">Botanical Blossom</span>
            </div>
            <p className="text-xs text-gray-300 leading-relaxed">
              Crafting premium flower arrangements for all life's precious moments with sustainable sourcing and doorstep delivery.
            </p>
          </div>

          <div>
            <h4 className="font-serif font-bold text-sm mb-4 tracking-wider uppercase text-[#E8DCC4]">Quick Links</h4>
            <ul className="space-y-2 text-xs text-gray-300">
              <li><button onClick={() => setActiveTab('catalog')} className="hover:text-white transition-colors">Our Collection</button></li>
              <li><button onClick={() => setActiveTab('builder')} className="hover:text-white transition-colors">Bouquet Builder</button></li>
              <li><button onClick={() => setActiveTab('care')} className="hover:text-white transition-colors">Flower Care Guide</button></li>
              <li><button onClick={() => setActiveTab('about')} className="hover:text-white transition-colors">About Us</button></li>
            </ul>
          </div>

          <div>
            <h4 className="font-serif font-bold text-sm mb-4 tracking-wider uppercase text-[#E8DCC4]">Contact Us</h4>
            <ul className="space-y-3 text-xs text-gray-300">
              <li className="flex items-center gap-2"><MapPin className="w-4 h-4 text-[#5C7053]" /> 123 Blossom Way, Floral District</li>
              <li className="flex items-center gap-2"><Phone className="w-4 h-4 text-[#5C7053]" /> +1 (555) 234-5678</li>
              <li className="flex items-center gap-2"><Mail className="w-4 h-4 text-[#5C7053]" /> support@botanicalblossom.com</li>
            </ul>
          </div>

          <div>
            <h4 className="font-serif font-bold text-sm mb-4 tracking-wider uppercase text-[#E8DCC4]">Stay Connected</h4>
            <p className="text-xs text-gray-300 mb-4">Subscribe to receive floral care hacks and seasonal discount codes.</p>
            <div className="flex items-center gap-2">
              <input 
                type="email" 
                placeholder="Enter your email" 
                className="bg-[#3D4A45] px-4 py-2 rounded-full text-xs text-white placeholder-gray-400 focus:outline-none w-full"
              />
              <button className="bg-[#5C7053] hover:bg-[#4A5B42] text-white px-4 py-2 rounded-full text-xs font-semibold">
                Join
              </button>
            </div>
          </div>

        </div>

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-8 border-t border-gray-700 flex flex-col sm:flex-row items-center justify-between text-xs text-gray-400">
          <p>&copy; 2026 Botanical Blossom. All rights reserved.</p>
          <div className="flex gap-4 mt-4 sm:mt-0">
            <span className="hover:text-white cursor-pointer"><Globe className="w-4 h-4 inline" /> English (US)</span>
            <span className="hover:text-white cursor-pointer">Privacy Policy</span>
            <span className="hover:text-white cursor-pointer">Terms of Service</span>
          </div>
        </div>
      </footer>

    </div>
  );
}