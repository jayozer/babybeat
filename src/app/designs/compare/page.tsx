'use client';

import { useState } from 'react';
import Link from 'next/link';
import { SereneCounterPage } from '@/designs/serene';
import { JoyfulCounterPage } from '@/designs/joyful';
import { ClinicalCounterPage } from '@/designs/clinical';

type DesignOption = 'serene' | 'joyful' | 'clinical';

const designs: { id: DesignOption; name: string; subtitle: string; color: string; bgColor: string }[] = [
  {
    id: 'serene',
    name: 'Serene',
    subtitle: 'Calming & Nurturing',
    color: '#5a8f5a',
    bgColor: '#e8f0e8',
  },
  {
    id: 'joyful',
    name: 'Joyful',
    subtitle: 'Playful & Warm',
    color: '#f96d55',
    bgColor: '#ffe8e4',
  },
  {
    id: 'clinical',
    name: 'Clinical',
    subtitle: 'Modern & Data-Focused',
    color: '#102a43',
    bgColor: '#d9e2ec',
  },
];

export default function DesignComparisonPage() {
  const [activeDesign, setActiveDesign] = useState<DesignOption>('serene');

  const renderDesign = (design: DesignOption) => {
    switch (design) {
      case 'serene':
        return <SereneCounterPage />;
      case 'joyful':
        return <JoyfulCounterPage />;
      case 'clinical':
        return <ClinicalCounterPage />;
    }
  };

  const activeInfo = designs.find(d => d.id === activeDesign)!;

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      {/* Compact Header */}
      <header className="bg-gray-900 border-b border-gray-800">
        <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
          <h1 className="text-lg font-bold">Baby Kick Count Designs</h1>
          <Link href="/" className="text-sm text-gray-400 hover:text-white">
            Back to App
          </Link>
        </div>
      </header>

      {/* Design Tabs - Large and Prominent */}
      <div className="bg-gray-900 border-b border-gray-800">
        <div className="max-w-7xl mx-auto px-4">
          <div className="flex">
            {designs.map((design) => (
              <button
                key={design.id}
                onClick={() => setActiveDesign(design.id)}
                className={`
                  flex-1 py-5 px-6 text-center transition-all relative
                  ${activeDesign === design.id
                    ? 'bg-gray-800'
                    : 'hover:bg-gray-800/50'
                  }
                `}
              >
                <div
                  className="w-4 h-4 rounded-full mx-auto mb-2"
                  style={{ backgroundColor: design.color }}
                />
                <div className="font-bold text-lg">{design.name}</div>
                <div className="text-sm text-gray-400">{design.subtitle}</div>
                {activeDesign === design.id && (
                  <div
                    className="absolute bottom-0 left-0 right-0 h-1"
                    style={{ backgroundColor: design.color }}
                  />
                )}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Main Preview Area */}
      <div className="flex flex-col lg:flex-row">
        {/* Large Phone Preview */}
        <div className="flex-1 flex items-center justify-center p-8 min-h-[80vh]">
          <div className="relative">
            {/* Phone Frame */}
            <div
              className="rounded-[3rem] p-2 shadow-2xl"
              style={{ backgroundColor: activeInfo.color }}
            >
              <div className="bg-black rounded-[2.5rem] p-1">
                <div className="w-[390px] h-[844px] bg-white rounded-[2.25rem] overflow-hidden relative">
                  {/* Notch */}
                  <div className="absolute top-0 left-1/2 -translate-x-1/2 w-28 h-7 bg-black rounded-b-2xl z-30" />

                  {/* Design Content */}
                  <div className="absolute inset-0 overflow-y-auto overflow-x-hidden">
                    {renderDesign(activeDesign)}
                  </div>
                </div>
              </div>
            </div>

            {/* Design Label */}
            <div
              className="absolute -bottom-6 left-1/2 -translate-x-1/2 px-6 py-2 rounded-full font-bold shadow-lg"
              style={{ backgroundColor: activeInfo.color, color: 'white' }}
            >
              {activeInfo.name}
            </div>
          </div>
        </div>

        {/* Side Panel with Info */}
        <div className="lg:w-80 bg-gray-900 p-6 border-l border-gray-800">
          <div className="sticky top-24 space-y-6">
            {/* Current Design Info */}
            <div
              className="rounded-2xl p-5"
              style={{ backgroundColor: activeInfo.bgColor }}
            >
              <h2 className="text-2xl font-bold text-gray-900 mb-1">
                {activeInfo.name}
              </h2>
              <p className="text-gray-600 text-sm">{activeInfo.subtitle}</p>
            </div>

            {/* Characteristics */}
            <div className="space-y-4">
              <h3 className="font-semibold text-gray-300 uppercase text-xs tracking-wider">
                Key Features
              </h3>
              {activeDesign === 'serene' && (
                <ul className="space-y-3 text-sm text-gray-400">
                  <li className="flex items-start gap-2">
                    <span className="text-green-400 mt-0.5">●</span>
                    Soft sage greens & warm cream
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-green-400 mt-0.5">●</span>
                    Breathing animations, gentle pulse
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-green-400 mt-0.5">●</span>
                    Progress ring with gradient
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-green-400 mt-0.5">●</span>
                    Glassmorphism timer card
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-green-400 mt-0.5">●</span>
                    Anxiety-reducing, calm vibe
                  </li>
                </ul>
              )}
              {activeDesign === 'joyful' && (
                <ul className="space-y-3 text-sm text-gray-400">
                  <li className="flex items-start gap-2">
                    <span className="text-orange-400 mt-0.5">●</span>
                    Warm coral, sunny yellow, teal
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-orange-400 mt-0.5">●</span>
                    Bouncy spring animations
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-orange-400 mt-0.5">●</span>
                    Confetti on goal completion
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-orange-400 mt-0.5">●</span>
                    Progress dots with heartbeat
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-orange-400 mt-0.5">●</span>
                    Celebratory, positive vibe
                  </li>
                </ul>
              )}
              {activeDesign === 'clinical' && (
                <ul className="space-y-3 text-sm text-gray-400">
                  <li className="flex items-start gap-2">
                    <span className="text-blue-400 mt-0.5">●</span>
                    Deep navy, clean white, teal
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-blue-400 mt-0.5">●</span>
                    Precise, minimal transitions
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-blue-400 mt-0.5">●</span>
                    Data cards with progress bars
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-blue-400 mt-0.5">●</span>
                    Timeline visualization
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-blue-400 mt-0.5">●</span>
                    Professional, trustworthy vibe
                  </li>
                </ul>
              )}
            </div>

            {/* Navigation Buttons */}
            <div className="space-y-3 pt-4">
              <button
                onClick={() => {
                  const ids: DesignOption[] = ['serene', 'joyful', 'clinical'];
                  const idx = ids.indexOf(activeDesign);
                  setActiveDesign(ids[(idx + 1) % 3]);
                }}
                className="w-full py-3 bg-white text-gray-900 rounded-xl font-semibold hover:bg-gray-100 transition-colors"
              >
                Next Design →
              </button>
              <button
                onClick={() => {
                  const ids: DesignOption[] = ['serene', 'joyful', 'clinical'];
                  const idx = ids.indexOf(activeDesign);
                  setActiveDesign(ids[(idx + 2) % 3]);
                }}
                className="w-full py-3 bg-gray-800 text-gray-300 rounded-xl font-semibold hover:bg-gray-700 transition-colors"
              >
                ← Previous Design
              </button>
            </div>

            {/* Quick Switch */}
            <div className="pt-4 border-t border-gray-800">
              <h3 className="font-semibold text-gray-300 uppercase text-xs tracking-wider mb-3">
                Quick Switch
              </h3>
              <div className="flex gap-2">
                {designs.map((d) => (
                  <button
                    key={d.id}
                    onClick={() => setActiveDesign(d.id)}
                    className={`
                      flex-1 py-2 rounded-lg text-xs font-medium transition-all
                      ${activeDesign === d.id
                        ? 'ring-2 ring-white'
                        : 'opacity-60 hover:opacity-100'
                      }
                    `}
                    style={{ backgroundColor: d.color, color: 'white' }}
                  >
                    {d.name}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
