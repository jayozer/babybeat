'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface NavItem {
  href: string;
  label: string;
  icon: React.ReactNode;
}

const CounterIcon = ({ active }: { active: boolean }) => (
  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect
      x="3"
      y="3"
      width="14"
      height="14"
      rx="3"
      stroke="currentColor"
      strokeWidth="1.5"
      fill={active ? 'currentColor' : 'none'}
      fillOpacity={active ? 0.15 : 0}
    />
    <path d="M10 6V14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <path d="M6 10H14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
  </svg>
);

const HistoryIcon = ({ active }: { active: boolean }) => (
  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect
      x="3"
      y="4"
      width="14"
      height="13"
      rx="2"
      stroke="currentColor"
      strokeWidth="1.5"
      fill={active ? 'currentColor' : 'none'}
      fillOpacity={active ? 0.15 : 0}
    />
    <path d="M3 8H17" stroke="currentColor" strokeWidth="1.5" />
    <path d="M7 4V2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <path d="M13 4V2" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <rect x="6" y="11" width="2" height="2" rx="0.5" fill="currentColor" />
    <rect x="9" y="11" width="2" height="2" rx="0.5" fill="currentColor" />
    <rect x="12" y="11" width="2" height="2" rx="0.5" fill="currentColor" />
  </svg>
);

const SettingsIcon = ({ active }: { active: boolean }) => (
  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path
      d="M8.5 3H11.5L12 5L14 6L16 5L18 7.5L16.5 9.5V10.5L18 12.5L16 15L14 14L12 15L11.5 17H8.5L8 15L6 14L4 15L2 12.5L3.5 10.5V9.5L2 7.5L4 5L6 6L8 5L8.5 3Z"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinejoin="round"
      fill={active ? 'currentColor' : 'none'}
      fillOpacity={active ? 0.15 : 0}
    />
    <circle cx="10" cy="10" r="2.5" stroke="currentColor" strokeWidth="1.5" />
  </svg>
);

const InfoIcon = ({ active }: { active: boolean }) => (
  <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle
      cx="10"
      cy="10"
      r="7"
      stroke="currentColor"
      strokeWidth="1.5"
      fill={active ? 'currentColor' : 'none'}
      fillOpacity={active ? 0.15 : 0}
    />
    <path d="M10 9V14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <circle cx="10" cy="6.5" r="1" fill="currentColor" />
  </svg>
);

const navItems: NavItem[] = [
  { href: '/', label: 'Counter', icon: <CounterIcon active={false} /> },
  { href: '/history', label: 'History', icon: <HistoryIcon active={false} /> },
  { href: '/settings', label: 'Settings', icon: <SettingsIcon active={false} /> },
  { href: '/info', label: 'Info', icon: <InfoIcon active={false} /> },
];

export function ClinicalBottomNav() {
  const pathname = usePathname();

  const isActive = (href: string) => {
    if (href === '/') {
      return pathname === '/';
    }
    return pathname.startsWith(href);
  };

  const getIcon = (href: string, label: string) => {
    const active = isActive(href);
    switch (label) {
      case 'Counter':
        return <CounterIcon active={active} />;
      case 'History':
        return <HistoryIcon active={active} />;
      case 'Settings':
        return <SettingsIcon active={active} />;
      case 'Info':
        return <InfoIcon active={active} />;
      default:
        return null;
    }
  };

  return (
    <nav
      className="
        fixed bottom-0 left-0 right-0
        bg-white border-t border-[#e2e8f0]
        safe-area-bottom
      "
      aria-label="Main navigation"
    >
      <div className="max-w-md mx-auto flex justify-around">
        {navItems.map((item) => {
          const active = isActive(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`
                flex flex-col items-center py-2.5 px-5
                transition-colors duration-150
                ${
                  active
                    ? 'text-[#102a43]'
                    : 'text-[#a0aec0] hover:text-[#627d98]'
                }
              `}
              aria-current={active ? 'page' : undefined}
            >
              {getIcon(item.href, item.label)}
              <span className={`text-xs mt-1 font-medium ${active && 'font-semibold'}`}>
                {item.label}
              </span>
              {active && (
                <span className="absolute bottom-0 w-8 h-0.5 bg-[#27ab83] rounded-t-full" />
              )}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
