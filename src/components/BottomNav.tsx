'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface NavItem {
  href: string;
  label: string;
}

// Serene icons - minimal line art style
const HomeIcon = ({ active }: { active: boolean }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <path
      d="M12 4C12 4 18 10 18 14C18 17.3137 15.3137 20 12 20C8.68629 20 6 17.3137 6 14C6 10 12 4 12 4Z"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
      strokeLinejoin="round"
      fill={active ? 'currentColor' : 'none'}
      fillOpacity={active ? 0.2 : 0}
    />
    <circle cx="12" cy="14" r="2" fill="currentColor" />
  </svg>
);

const HistoryIcon = ({ active }: { active: boolean }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <rect
      x="4"
      y="5"
      width="16"
      height="16"
      rx="3"
      stroke="currentColor"
      strokeWidth="1.5"
      fill={active ? 'currentColor' : 'none'}
      fillOpacity={active ? 0.2 : 0}
    />
    <path d="M4 10H20" stroke="currentColor" strokeWidth="1.5" />
    <path d="M9 5V3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <path d="M15 5V3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <circle cx="9" cy="15" r="1.5" fill="currentColor" />
    <circle cx="15" cy="15" r="1.5" fill="currentColor" />
  </svg>
);

const SettingsIcon = ({ active }: { active: boolean }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle
      cx="12"
      cy="12"
      r="3"
      stroke="currentColor"
      strokeWidth="1.5"
      fill={active ? 'currentColor' : 'none'}
      fillOpacity={active ? 0.2 : 0}
    />
    <path
      d="M12 5V3M12 21V19M5 12H3M21 12H19M7.05 7.05L5.636 5.636M18.364 18.364L16.95 16.95M7.05 16.95L5.636 18.364M18.364 5.636L16.95 7.05"
      stroke="currentColor"
      strokeWidth="1.5"
      strokeLinecap="round"
    />
  </svg>
);

const InfoIcon = ({ active }: { active: boolean }) => (
  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle
      cx="12"
      cy="12"
      r="9"
      stroke="currentColor"
      strokeWidth="1.5"
      fill={active ? 'currentColor' : 'none'}
      fillOpacity={active ? 0.2 : 0}
    />
    <path d="M12 11V16" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
    <circle cx="12" cy="8" r="1" fill="currentColor" />
  </svg>
);

const navItems: NavItem[] = [
  { href: '/', label: 'Count' },
  { href: '/history', label: 'History' },
  { href: '/settings', label: 'Settings' },
  { href: '/info', label: 'Help' },
];

export function BottomNav() {
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
      case 'Count':
        return <HomeIcon active={active} />;
      case 'History':
        return <HistoryIcon active={active} />;
      case 'Settings':
        return <SettingsIcon active={active} />;
      case 'Help':
        return <InfoIcon active={active} />;
      default:
        return null;
    }
  };

  return (
    <nav
      className="
        flex-shrink-0
        bg-white/80 backdrop-blur-md
        border-t border-[#e8f0e8]
        safe-area-bottom
      "
      aria-label="Main navigation"
    >
      <div className="max-w-md mx-auto flex justify-around py-1">
        {navItems.map((item) => {
          const active = isActive(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`
                flex flex-col items-center py-2 px-5
                transition-all duration-200
                rounded-2xl my-1
                ${
                  active
                    ? 'text-[#477347] bg-[#e8f0e8]/50'
                    : 'text-[#a5ada5] hover:text-[#6b736b] hover:bg-[#f6f9f6]'
                }
              `}
              aria-current={active ? 'page' : undefined}
            >
              {getIcon(item.href, item.label)}
              <span className="text-xs mt-1 font-medium">{item.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
