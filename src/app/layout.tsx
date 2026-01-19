import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { Providers } from "./providers";
import { BottomNav } from "@/components/BottomNav";
import { ServiceWorkerRegistration } from "@/components/ServiceWorkerRegistration";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Baby Kick Count",
  description: "A gentle, calming app to help expectant parents track fetal movements during pregnancy",
  manifest: "/manifest.json",
  metadataBase: new URL("https://babykickcount.com"),
  openGraph: {
    title: "Baby Kick Count",
    description: "A gentle, calming app to help expectant parents track fetal movements during pregnancy",
    url: "https://babykickcount.com",
    siteName: "Baby Kick Count",
    images: [
      {
        url: "/baby_kick_count_carousel.png",
        width: 1200,
        height: 630,
        alt: "Baby Kick Count - Track your baby's movements gently",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Baby Kick Count",
    description: "A gentle, calming app to help expectant parents track fetal movements during pregnancy",
    images: ["/baby_kick_count_carousel.png"],
  },
  appleWebApp: {
    capable: true,
    statusBarStyle: "default",
    title: "Baby Kick Count",
  },
  icons: {
    icon: [
      { url: "/icons/icon.svg", type: "image/svg+xml" },
    ],
    apple: [
      { url: "/icons/icon.svg" },
    ],
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: "cover",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="h-full">
      <body
        className={`${geistSans.variable} ${geistMono.variable} antialiased h-full flex flex-col`}
      >
        <div className="flex-1 overflow-y-auto">
          <Providers>{children}</Providers>
        </div>
        <BottomNav />
        <ServiceWorkerRegistration />
      </body>
    </html>
  );
}
