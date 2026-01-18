'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';

interface NavItem {
  href: string;
  label: string;
  icon: string;
}

const navItems: NavItem[] = [
  { href: '/', label: 'Counter', icon: '👶' },
  { href: '/history', label: 'History', icon: '📅' },
  { href: '/settings', label: 'Settings', icon: '⚙️' },
  { href: '/info', label: 'Info', icon: '❓' },
];

export function BottomNav() {
  const pathname = usePathname();

  // Check if current path matches nav item (handle /session/[id])
  const isActive = (href: string) => {
    if (href === '/') {
      return pathname === '/';
    }
    return pathname.startsWith(href);
  };

  return (
    <nav
      className="
        fixed bottom-0 left-0 right-0
        bg-white border-t border-gray-200
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
                flex flex-col items-center py-2 px-4
                transition-colors
                ${
                  active
                    ? 'text-pink-500'
                    : 'text-gray-500 hover:text-gray-700'
                }
              `}
              aria-current={active ? 'page' : undefined}
            >
              <span className="text-xl">{item.icon}</span>
              <span className="text-xs mt-0.5 font-medium">{item.label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
