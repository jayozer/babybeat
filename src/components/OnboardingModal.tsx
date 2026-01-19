'use client';

import { useEffect, useState } from 'react';

const ONBOARDED_KEY = 'babybeat_onboarded';

interface OnboardingModalProps {
  onComplete: () => void;
  isOpen?: boolean;
}

export function OnboardingModal({ onComplete, isOpen = true }: OnboardingModalProps) {
  const [step, setStep] = useState(0);

  const steps = [
    {
      emoji: '👶',
      title: 'Welcome to Baby Kick Counter',
      content: (
        <>
          <p>
            Counting your baby&apos;s movements is a simple way to monitor their
            well-being during pregnancy.
          </p>
          <p className="mt-3">
            Most healthcare providers recommend counting kicks starting around
            28 weeks.
          </p>
        </>
      ),
    },
    {
      emoji: '⏰',
      title: 'How to Count',
      content: (
        <ol className="list-decimal list-inside space-y-2">
          <li>Choose a time when your baby is usually active</li>
          <li>Get comfortable - lie on your side or sit with feet up</li>
          <li>Start the counter and tap each time you feel movement</li>
          <li>Count any kick, roll, jab, or flutter</li>
          <li>Stop when you reach 10 movements</li>
        </ol>
      ),
    },
    {
      emoji: '🎯',
      title: 'The 10 in 2 Hours Goal',
      content: (
        <>
          <p>
            The goal is to feel <strong>10 movements within 2 hours</strong>.
          </p>
          <p className="mt-3">
            Most babies will reach 10 kicks in much less time. If you don&apos;t
            reach 10 in 2 hours, try techniques to encourage movement.
          </p>
          <p className="mt-3 text-sm text-[#858e85]">
            If movements seem decreased or you&apos;re concerned,{' '}
            <strong className="text-[#6b736b]">contact your healthcare provider</strong>.
          </p>
        </>
      ),
    },
    {
      emoji: '🚀',
      title: "You're Ready!",
      content: (
        <>
          <p>Tap the big button whenever you feel your baby move.</p>
          <p className="mt-3">
            Your sessions are saved locally on your device for you to review
            anytime.
          </p>
          <p className="mt-3 text-sm text-[#858e85]">
            This app is for educational purposes only and does not replace
            medical advice.
          </p>
        </>
      ),
    },
  ];

  const currentStep = steps[step];
  const isLastStep = step === steps.length - 1;

  const handleNext = () => {
    if (isLastStep) {
      localStorage.setItem(ONBOARDED_KEY, 'true');
      onComplete();
    } else {
      setStep((s) => s + 1);
    }
  };

  const handleSkip = () => {
    localStorage.setItem(ONBOARDED_KEY, 'true');
    onComplete();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div
        className="bg-white/95 backdrop-blur-md rounded-3xl p-6 max-w-md w-full shadow-[0_8px_32px_rgba(90,143,90,0.15)] max-h-[90vh] overflow-y-auto animate-fade-in"
        role="dialog"
        aria-modal="true"
        aria-labelledby="onboarding-title"
      >
        {/* Progress dots */}
        <div className="flex justify-center gap-2 mb-6">
          {steps.map((_, i) => (
            <span
              key={i}
              className={`
                w-2 h-2 rounded-full transition-all duration-300
                ${i === step ? 'bg-[#5a8f5a] scale-125' : 'bg-[#e8f0e8]'}
              `}
              aria-hidden="true"
            />
          ))}
        </div>

        {/* Content */}
        <div className="text-center mb-6">
          <div className="text-5xl mb-3">{currentStep.emoji}</div>
          <h2
            id="onboarding-title"
            className="text-xl font-semibold text-[#494d49] mb-4"
            style={{ fontFamily: 'Quicksand, sans-serif' }}
          >
            {currentStep.title}
          </h2>
          <div className="text-[#6b736b] text-left">{currentStep.content}</div>
        </div>

        {/* Actions */}
        <div className="flex flex-col gap-3">
          <button
            type="button"
            onClick={handleNext}
            className="
              w-full py-4 rounded-2xl
              bg-gradient-to-r from-[#a8c9a8] to-[#7bab7b]
              text-white font-semibold text-lg
              shadow-[0_4px_20px_rgba(90,143,90,0.25)]
              transition-all duration-300
              hover:shadow-[0_8px_30px_rgba(90,143,90,0.35)]
              active:scale-[0.98]
            "
          >
            {isLastStep ? "Let's Go!" : 'Next'}
          </button>
          {!isLastStep && (
            <button
              type="button"
              onClick={handleSkip}
              className="
                w-full py-3 rounded-2xl
                text-[#858e85] font-medium
                hover:bg-[#f6f9f6] active:bg-[#e8f0e8]
                transition-all duration-200
              "
            >
              Skip
            </button>
          )}
        </div>
      </div>
    </div>
  );
}

/**
 * Hook to check if onboarding should be shown
 */
export function useOnboarding() {
  const [shouldShowOnboarding, setShouldShowOnboarding] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const onboarded = localStorage.getItem(ONBOARDED_KEY);
    setShouldShowOnboarding(!onboarded);
    setIsLoading(false);
  }, []);

  const completeOnboarding = () => {
    localStorage.setItem(ONBOARDED_KEY, 'true');
    setShouldShowOnboarding(false);
  };

  const resetOnboarding = () => {
    localStorage.removeItem(ONBOARDED_KEY);
    setShouldShowOnboarding(true);
  };

  return {
    shouldShowOnboarding,
    isLoading,
    completeOnboarding,
    resetOnboarding,
  };
}
