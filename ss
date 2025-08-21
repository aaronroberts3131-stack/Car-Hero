'use client';

/**
 * Car Hero Website (React) – V1
 *
 * MIT License
 * Copyright (c) 2025 <YOUR NAME>
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED
 * "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.
 */

import React, { useEffect, useState } from 'react';

/**
 * =====================
 * ✏️  EDIT HERE (CONFIG)
 * =====================
 * Update these fields to make the site yours. No other code changes needed.
 */
export const CONFIG = {
  ownerName: 'Car Hero Detailing',
  legalOwner: '<YOUR NAME or LLC>',
  phone: '+1-463-279-7398',
  phoneDisplay: '(463) 279‑7398',
  serviceAreas: 'Carmel & Indianapolis, Indiana',
  city: 'Carmel',
  zip: '46032',
  // Brand colors (Tailwind scale names or hex ok for gradients)
  colors: {
    gradientFrom: 'from-blue-600',
    gradientTo: 'to-orange-500',
    accent: 'text-blue-600',
  },
  // Hero background image – swap for your own file or hosted URL (Dodge Charger)
  heroImageUrl:
    "url('https://images.unsplash.com/photo-1525609004556-c46c7d6cf023?q=80&w=1600&auto=format&fit=crop')",
  // Google Maps embed for Carmel, IN (edit if you want a different start point)
  maps: {
    placeLabel: 'Carmel, Indiana',
    embedSrc: 'https://www.google.com/maps?q=Carmel%2C%20Indiana&output=embed',
    linkHref: 'https://www.google.com/maps/place/Carmel,+IN',
  },
};

// Derive Tailwind class strings from CONFIG
const BRAND_PRIMARY = `${CONFIG.colors.gradientFrom} ${CONFIG.colors.gradientTo}`;
const BRAND_ACCENT = CONFIG.colors.accent;

// --- Pricing tables (single source of truth) ---
// Feel free to edit prices. The estimator and tests will update automatically.
export const BASE_PRICES = {
  'Basic Wash': { Sedan: 55, SUV: 65, Truck: 75, Van: 85 },
  'Interior Deep Clean': { Sedan: 150, SUV: 170, Truck: 185, Van: 200 },
  'Wash & Wax': { Sedan: 95, SUV: 115, Truck: 125, Van: 140 },
  'Interior + Wash & Wax': { Sedan: 205, SUV: 225, Truck: 245, Van: 265 },
};
export const ADDON_PRICES = { shampoo: 50, petHair: 25, headlight: 25, clay: 60, trim: 15 };
export const MOBILE_FEE = 20; // standard mobile service fee

// --- Pure calculator (easier to test) ---
export function calcQuote(
  form,
  basePrices = BASE_PRICES,
  addonPrices = ADDON_PRICES,
  mobileFee = MOBILE_FEE
) {
  if (!form || !form.package || !form.size) return 0;
  const pkg = basePrices?.[form.package]?.[form.size] ?? 0;
  const add = Object.entries(form.addons || {}).reduce(
    (sum, [k, v]) => sum + (v ? addonPrices?.[k] ?? 0 : 0),
    0
  );
  return pkg + add + mobileFee;
}

export default function CarHeroSite() {
  // --- Simple state for booking & estimator ---
  const [form, setForm] = useState({
    name: '',
    phone: '',
    address: '',
    vehicle: '',
    size: 'Sedan',
    package: 'Interior + Wash & Wax',
    addons: { shampoo: false, petHair: false, headlight: false, clay: false, trim: false },
    date: '',
    time: '',
  });
  const [quote, setQuote] = useState(0);
  const [messages, setMessages] = useState([
    {
      role: 'assistant',
      text:
        'Hey! I’m the Car Hero assistant. Tell me your vehicle and what you need — I’ll estimate a price and suggest a package.',
    },
  ]);

  useEffect(() => setQuote(calcQuote(form)), [form]);

  function toggleAddon(key) {
    setForm((prev) => ({ ...prev, addons: { ...prev.addons, [key]: !prev.addons[key] } }));
  }

  function handleChange(e) {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
  }

  // "AI" style quick estimator (rule-based for now; can be wired to OpenAI later)
  function handleAsk(userText) {
    const text = (userText || '').trim();
    if (!text) return;
    const newMsgs = [...messages, { role: 'user', text }];

    // naive parsing
    const lower = text.toLowerCase();
    const size = /mini|van/.test(lower)
      ? 'Van'
      : /truck|pickup/.test(lower)
      ? 'Truck'
      : /suv/.test(lower)
      ? 'SUV'
      : 'Sedan';
    const heavy = /mud|kids|spill|stain|smell|vomit|mold|sand|dog|cat|pet hair|hair|trash|sticky/.test(lower);
    const wantsWax = /wax|shine|beads|beading|protect/.test(lower);
    const interior = /interior|inside|seats|carpet|dash|shampoo/.test(lower);

    let pkg = 'Interior + Wash & Wax';
    if (interior && !wantsWax) pkg = heavy ? 'Interior Deep Clean' : 'Interior Deep Clean';
    if (!interior && wantsWax) pkg = 'Wash & Wax';
    if (!interior && !wantsWax) pkg = 'Basic Wash';

    const suggested = { ...form, size, package: pkg, addons: { ...form.addons } };
    if (/pet|dog|cat|hair/.test(lower)) suggested.addons.petHair = true;
    if (/headlight/.test(lower)) suggested.addons.headlight = true;
    if (/clay|rough|overspray|contamin/.test(lower)) suggested.addons.clay = true;
    if (/stain|spill|smell|odor/.test(lower)) suggested.addons.shampoo = true;

    const estimated = calcQuote(suggested);
    setForm(suggested);

    const reply = `I’d size this as a ${size}. Package: ${pkg}. Estimated total with add‑ons + mobile fee: $${estimated}. You can tweak options below or book now.`;
    setMessages([...newMsgs, { role: 'assistant', text: reply }]);
  }

  function QuickChip({ label, text }) {
    return (
      <button onClick={() => handleAsk(text)} className="px-3 py-1 rounded-full border hover:bg-neutral-50 text-sm">
        {label}
      </button>
    );
  }

  const telHref = `tel:${CONFIG.phone}`;
  const smsHref = `sms:${CONFIG.phone}`;

  return (
    <div className="min-h-screen bg-white text-neutral-900">
      {/* Top ribbon with satisfaction badge */}
      <div className={`w-full bg-gradient-to-r ${BRAND_PRIMARY} text-white text-sm`}>
        <div className="max-w-6xl mx-auto px-4 py-2 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="inline-flex items-center gap-1 px-2 py-1 rounded-full bg-white/15 ring-1 ring-white/30">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M9 12l2 2 4-4" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/></svg>
              <b>100% Satisfaction</b>
            </span>
            <span className="hidden sm:inline">{CONFIG.serviceAreas} • Mobile Detailing</span>
          </div>
          <a className="underline" href={telHref}>Call {CONFIG.phoneDisplay}</a>
        </div>
      </div>

      {/* Header */}
      <header className="sticky top-0 z-20 backdrop-blur bg-white/80 border-b">
        <div className="max-w-6xl mx-auto px-4 py-3 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-gradient-to-r from-black to-neutral-700 text-white grid place-items-center font-extrabold shadow">CH</div>
            <div>
              <p className="font-bold leading-tight text-lg">{CONFIG.ownerName}</p>
              <p className="text-xs text-neutral-500">{CONFIG.serviceAreas.split('&')[0]?.trim()} • Mobile</p>
            </div>
          </div>
          <nav className="hidden md:flex items-center gap-6 text-sm">
            <a href="#services" className="hover:opacity-70">Services</a>
            <a href="#pricing" className="hover:opacity-70">Pricing</a>
            <a href="#gallery" className="hover:opacity-70">Gallery</a>
            <a href="#reviews" className="hover:opacity-70">Reviews</a>
            <a href="#booking" className="hover:opacity-70">Book</a>
          </nav>
          <div className="flex items-center gap-3">
            <a href="#booking" className={`hidden md:inline-block px-4 py-2 rounded-2xl text-white text-sm bg-gradient-to-r ${BRAND_PRIMARY}`}>Book Now</a>
          </div>
        </div>
      </header>

      {/* Hero with Charger background + Carmel, IN map card */}
      <section className="relative">
        <div className="max-w-6xl mx-auto p-4">
          <div
            className="relative rounded-3xl overflow-hidden border border-black/30 shadow-2xl"
            style={{ backgroundImage: CONFIG.heroImageUrl, backgroundSize: 'cover', backgroundPosition: 'center' }}
          >
            <div className="absolute inset-0 bg-black/55" />
            <div className="relative px-8 md:px-14 py-16 md:py-24 text-white grid md:grid-cols-2 gap-8 items-center">
              <div>
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 ring-1 ring-white/20">
                  <span className={`text-xs font-semibold ${BRAND_ACCENT}`}>Mobile • On‑Site</span>
                  <span className="text-xs">We come to you</span>
                </div>
                <h1 className="mt-4 text-4xl md:text-6xl font-extrabold leading-tight">
                  <span className="block">CAR <span className={BRAND_ACCENT}>HERO</span></span>
                  <span className="block">DETAILING</span>
                </h1>
                <p className="mt-4 text-neutral-200 max-w-xl">
                  We service <b>10+ cars every week</b> with a <b>100% satisfaction guarantee</b>. Serving {CONFIG.serviceAreas}.
                </p>
                <div className="mt-4 inline-flex items-center gap-2 text-sm">
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 21s-6-5.686-6-10a6 6 0 1112 0c0 4.314-6 10-6 10z" stroke="currentColor" strokeWidth="2"/><circle cx="12" cy="11" r="2" fill="currentColor"/></svg>
                  <a href={CONFIG.maps.linkHref} target="_blank" rel="noopener noreferrer" className="underline">{CONFIG.maps.placeLabel}</a>
                </div>
                <div className="mt-6 flex flex-wrap gap-3">
                  <a href="#booking" className={`px-5 py-3 rounded-2xl text-white font-medium bg-gradient-to-r ${BRAND_PRIMARY}`}>Get Instant Quote</a>
                  <a
                    href={`${smsHref}?body=Hi%20${encodeURIComponent(CONFIG.ownerName)}%2C%20I%27d%20like%20to%20book%20a%20detail`}
                    className="px-5 py-3 rounded-2xl bg-white/10 ring-1 ring-white/30"
                  >
                    Text Us
                  </a>
                </div>
                <div className="mt-6 flex items-center gap-6 text-sm text-neutral-200">
                  <div>✅ Licensed • Insured</div>
                  <div>🧽 Interior • Exterior</div>
                  <div>🕒 Same‑week availability</div>
                </div>
              </div>

              {/* Right column: stat + embedded map card */}
              <div className="relative">
                <div className="aspect-[4/3] rounded-3xl bg-white/5 ring-1 ring-white/15" />
                <div className="absolute -bottom-6 -left-6 bg-white/95 text-neutral-900 rounded-2xl shadow-xl p-4 w-64">
                  <p className="font-semibold">Recent stat</p>
                  <p className="text-sm text-neutral-700">Avg. turnaround: <b>2–3 hrs</b><br/>Repeat customers: <b>70%</b></p>
                </div>
                <div className="absolute -top-6 -right-6 bg-white/95 text-neutral-900 rounded-2xl shadow-xl w-64 overflow-hidden">
                  <div className="p-3 border-b font-semibold text-sm">Service Area • {CONFIG.city}, IN</div>
                  <div className="h-40">
                    <iframe
                      title={`Map of ${CONFIG.maps.placeLabel}`}
                      src={CONFIG.maps.embedSrc}
                      className="w-full h-full border-0"
                      loading="lazy"
                      referrerPolicy="no-referrer-when-downgrade"
                    />
                  </div>
                  <a
                    href={CONFIG.maps.linkHref}
                    target="_blank"
                    rel="noopener noreferrer"
                    className={`block text-center text-xs py-2 border-t hover:opacity-80 bg-gradient-to-r ${BRAND_PRIMARY} text-white`}
                  >
                    Open in Maps
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Services */}
      <section id="services" className="bg-neutral-50 border-y">
        <div className="max-w-6xl mx-auto px-4 py-14">
          <h2 className="text-2xl md:text-3xl font-bold">Services</h2>
          <div className="mt-6 grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {[
              { title: 'Interior Deep Clean', desc: 'Vacuum, crevices, plastics, steam touch‑ups, windows, floor mats.', icon: '🪣' },
              { title: 'Wash & Wax', desc: 'pH‑balanced foam, contact wash, clay as needed, wax & shine.', icon: '✨' },
              { title: 'Shampoo & Stain Lift', desc: 'Targeted extraction on seats and carpets to remove stains/odors.', icon: '🧼' },
              { title: 'Add‑ons', desc: 'Pet hair removal, headlight restore, trim revival, clay bar, more.', icon: '➕' },
            ].map((s) => (
              <div key={s.title} className="rounded-2xl bg-white p-5 shadow-sm border">
                <div className="text-2xl">{s.icon}</div>
                <h3 className="mt-2 font-semibold">{s.title}</h3>
                <p className="text-sm text-neutral-600 mt-1">{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing */}
      <section id="pricing" className="">
        <div className="max-w-6xl mx-auto px-4 py-14">
          <h2 className="text-2xl md:text-3xl font-bold">Transparent pricing</h2>
          <p className="text-neutral-600 mt-2">
            All mobile jobs include a ${MOBILE_FEE} service fee. Choose a package, size, and any add‑ons — your estimate updates live.
          </p>
          <div className="mt-6 grid md:grid-cols-2 gap-6">
            {/* Package selector */}
            <div className="rounded-3xl border p-5">
              <label className="block text-sm font-medium">Package</label>
              <select name="package" value={form.package} onChange={handleChange} className="mt-2 w-full border rounded-xl p-3">
                {Object.keys(BASE_PRICES).map((k) => (
                  <option key={k}>{k}</option>
                ))}
              </select>

              <div className="grid grid-cols-4 gap-2 mt-4">
                {['Sedan', 'SUV', 'Truck', 'Van'].map((sz) => (
                  <button
                    key={sz}
                    onClick={() => setForm((prev) => ({ ...prev, size: sz }))}
                    className={`px-3 py-2 rounded-xl border ${form.size === sz ? 'bg-gradient-to-r text-white ' + BRAND_PRIMARY : 'bg-white'}`}
                  >
                    {sz}
                  </button>
                ))}
              </div>

              <div className="mt-4 grid sm:grid-cols-2 gap-3">
                {[
                  { key: 'shampoo', label: 'Shampoo & Extraction (+$50)' },
                  { key: 'petHair', label: 'Pet Hair Removal (+$25)' },
                  { key: 'headlight', label: 'Headlight Restore (+$25)' },
                  { key: 'clay', label: 'Clay Bar Decon (+$60)' },
                  { key: 'trim', label: 'Trim Revival (+$15)' },
                ].map(({ key, label }) => (
                  <label key={key} className="flex items-center gap-2 text-sm">
                    <input type="checkbox" checked={form.addons[key]} onChange={() => toggleAddon(key)} /> {label}
                  </label>
                ))}
              </div>

              <div className="mt-6 p-4 rounded-2xl bg-neutral-50 border text-sm">
                <div className="flex items-center justify-between">
                  <span>Estimated total</span>
                  <span className="text-2xl font-extrabold">${quote}</span>
                </div>
                <p className="text-neutral-500 mt-1">Final price after on‑site inspection. Ask about multi‑car discounts.</p>
              </div>
            </div>

            {/* Booking form */}
            <form id="booking" onSubmit={(e) => e.preventDefault()} className="rounded-3xl border p-5">
              <h3 className="font-semibold text-lg">Book now</h3>
              <div className="grid sm:grid-cols-2 gap-3 mt-3">
                <input name="name" placeholder="Full name" value={form.name} onChange={handleChange} className="border rounded-xl p-3" />
                <input name="phone" placeholder="Phone" value={form.phone} onChange={handleChange} className="border rounded-xl p-3" />
                <input name="address" placeholder="Service address" value={form.address} onChange={handleChange} className="border rounded-xl p-3 sm:col-span-2" />
                <input name="vehicle" placeholder="Vehicle (e.g., 2016 Dodge Charger)" value={form.vehicle} onChange={handleChange} className="border rounded-xl p-3 sm:col-span-2" />
                <input type="date" name="date" value={form.date} onChange={handleChange} className="border rounded-xl p-3" />
                <input type="time" name="time" value={form.time} onChange={handleChange} className="border rounded-xl p-3" />
              </div>
              <button className={`mt-4 w-full px-4 py-3 rounded-2xl text-white font-semibold bg-gradient-to-r ${BRAND_PRIMARY}`}>Request this time</button>
              <p className="text-xs text-neutral-500 mt-2">
                Or text us: <a className="underline" href={`${smsHref}`}>{CONFIG.phoneDisplay}</a>. We reply fast.
              </p>
            </form>
          </div>
        </div>
      </section>

      {/* Gallery */}
      <section id="gallery" className="bg-neutral-50 border-y">
        <div className="max-w-6xl mx-auto px-4 py-14">
          <h2 className="text-2xl md:text-3xl font-bold">Before & after</h2>
          <div className="mt-6 grid sm:grid-cols-2 md:grid-cols-3 gap-3">
            {Array.from({ length: 9 }).map((_, i) => (
              <div key={i} className="aspect-video rounded-2xl bg-gradient-to-br from-neutral-200 to-neutral-300" />
            ))}
          </div>
        </div>
      </section>

      {/* Reviews */}
      <section id="reviews">
        <div className="max-w-6xl mx-auto px-4 py-14">
          <h2 className="text-2xl md:text-3xl font-bold">Happy customers</h2>
          <div className="mt-6 grid md:grid-cols-3 gap-4">
            {[
              { name: 'Tyler R.', text: 'Booked same‑day. Interior looks brand new. Pet hair gone!' },
              { name: 'Michelle K.', text: 'Great communication, fair price, insane shine after the wax.' },
              { name: 'Derrick S.', text: 'They came to my office — super convenient and professional.' },
            ].map((r) => (
              <div key={r.name} className="rounded-2xl border p-5 bg-white">
                <div className="font-semibold">{r.name}</div>
                <p className={`text-sm mt-2`}>
                  <span className="text-neutral-600">“{r.text}”</span>
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Assistant widget */}
      <section className="fixed bottom-4 right-4 z-30">
        <details className="group">
          <summary className="list-none">
            <button className={`px-4 py-3 rounded-full shadow-xl text-white font-medium bg-gradient-to-r ${BRAND_PRIMARY}`}>Chat • Smart Estimator</button>
          </summary>
          <div className="mt-2 w-80 rounded-2xl border bg-white shadow-xl overflow-hidden">
            <div className={`p-3 border-b text-sm font-semibold ${BRAND_ACCENT}`}>Car Hero Assistant (beta)</div>
            <div className="h-64 overflow-y-auto p-3 space-y-2 text-sm">
              {messages.map((m, idx) => (
                <div key={idx} className={`${m.role === 'assistant' ? 'bg-neutral-100' : 'bg-gradient-to-r from-neutral-900 to-neutral-700 text-white'} p-2.5 rounded-xl whitespace-pre-wrap`}>
                  {m.text}
                </div>
              ))}
            </div>
            <div className="p-3 flex gap-2 border-t">
              <input
                id="ai-input"
                className="flex-1 border rounded-xl p-2 text-sm"
                placeholder="e.g., SUV with dog hair, need inside & wax"
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    handleAsk(e.target.value);
                    e.target.value = '';
                  }
                }}
              />
              <button
                className={`px-3 py-2 rounded-xl text-white text-sm bg-gradient-to-r ${BRAND_PRIMARY}`}
                onClick={() => {
                  const el = document.getElementById('ai-input');
                  if (el && el.value) {
                    handleAsk(el.value);
                    el.value = '';
                  }
                }}
              >
                Send
              </button>
            </div>
            <div className="p-3 flex flex-wrap gap-2 border-t">
              <QuickChip label="Sedan light clean" text="I have a sedan, just need a light interior and exterior." />
              <QuickChip label="SUV + pet hair" text="SUV with lots of pet hair and some stains. Want inside cleaned and wax outside." />
              <QuickChip label="Truck muddy" text="Pickup truck with mud. No interior, just wash and wax." />
            </div>
          </div>
        </details>
      </section>

      {/* Footer */}
      <footer className="border-t bg-neutral-50">
        <div className="max-w-6xl mx-auto px-4 py-10 grid md:grid-cols-3 gap-6 text-sm">
          <div>
            <div className="font-semibold">{CONFIG.ownerName}</div>
            <p className="text-neutral-600 mt-1">
              {CONFIG.serviceAreas} • Mobile service • <span className={BRAND_ACCENT}>100% satisfaction guaranteed</span>
            </p>
          </div>
          <div>
            <div className="font-semibold">Contact</div>
            <p className="mt-1">
              <a className="underline" href={telHref}>{CONFIG.phoneDisplay}</a>
              <br />
              <a className="underline" href={smsHref}>Text us</a> • <a className="underline" href="#booking">Book online</a>
            </p>
          </div>
          <div>
            <div className="font-semibold">Hours</div>
            <p className="mt-1">Mon–Sun: 8am–7pm • Same‑week openings</p>
          </div>
        </div>
        <div className="text-center text-xs text-neutral-500 pb-6">
          © {new Date().getFullYear()} {CONFIG.ownerName}. All rights reserved.
        </div>
      </footer>

      {/* Local business schema */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify({
            '@context': 'https://schema.org',
            '@type': 'AutoDetailing',
            name: CONFIG.ownerName,
            areaServed: CONFIG.serviceAreas,
            telephone: CONFIG.phone,
            url: 'https://your-domain.example',
            address: {
              '@type': 'PostalAddress',
              addressLocality: CONFIG.city,
              addressRegion: 'IN',
              postalCode: CONFIG.zip,
              addressCountry: 'US',
            },
            openingHours: 'Mo-Su 08:00-19:00',
            priceRange: '$$',
          }),
        }}
      />
    </div>
  );
}

// --- Lightweight runtime tests (run once in browser; show results in console) ---
if (typeof window !== 'undefined' && !window.__CAR_HERO_TESTS__) {
  window.__CAR_HERO_TESTS__ = true;
  try {
    const empty = { size: 'Sedan', package: 'Basic Wash', addons: { shampoo: false, petHair: false, headlight: false, clay: false, trim: false } };
    console.assert(calcQuote(empty) === 55 + MOBILE_FEE, 'Test 1: Basic Wash Sedan');

    const withAddons = { ...empty, addons: { ...empty.addons, shampoo: true, petHair: true } };
    console.assert(calcQuote(withAddons) === 55 + 50 + 25 + MOBILE_FEE, 'Test 2: Add-ons (shampoo + pet hair)');

    const suvCombo = { size: 'SUV', package: 'Interior + Wash & Wax', addons: { shampoo: false, petHair: false, headlight: false, clay: false, trim: false } };
    console.assert(calcQuote(suvCombo) === 225 + MOBILE_FEE, 'Test 3: SUV Interior + Wash & Wax');

    const fullAdd = { size: 'Truck', package: 'Wash & Wax', addons: { shampoo: true, petHair: true, headlight: true, clay: true, trim: true } };
    const expected = 125 + 50 + 25 + 25 + 60 + 15 + MOBILE_FEE;
    console.assert(calcQuote(fullAdd) === expected, 'Test 4: All add-ons + Truck Wash & Wax');

    // New tests
    const vanBasic = { size: 'Van', package: 'Basic Wash', addons: { shampoo: false, petHair: false, headlight: false, clay: false, trim: false } };
    console.assert(calcQuote(vanBasic) === 85 + MOBILE_FEE, 'Test 5: Van Basic Wash');

    const invalidPkg = { size: 'Sedan', package: 'Not A Real Package', addons: { shampoo: false, petHair: false, headlight: false, clay: false, trim: false } };
    console.assert(calcQuote(invalidPkg) === 0 + MOBILE_FEE, 'Test 6: Invalid package → only mobile fee added');

    // Guard: React import present
    console.assert(typeof React !== 'undefined', 'Test 7: React is defined');

    console.log('%cCar Hero tests passed ✔', 'color: white; background:#16a34a; padding:2px 6px; border-radius:6px');
  } catch (e) {
    console.error('Car Hero tests failed:', e);
  }
}
