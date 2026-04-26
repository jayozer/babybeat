/* Tweaks panel for babykickcount.com */
const { useEffect } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "palette": "sage",
  "typePairing": "fraunces-quicksand",
  "heroHeadline": "A calm way to count your baby's movements.",
  "heroLede": "One tap per kick. Nothing else. No ads, no accounts, no data leaving your phone — just a quiet companion for the moments that matter most."
}/*EDITMODE-END*/;

const PALETTES = {
  sage:    { cream:"#f5f1e8", creamSoft:"#faf6ec", creamDeep:"#ede7d8", sage:"#8fa68e", sageDeep:"#6d8a6c", sageSoft:"#c8d4c5", blush:"#e8c4b8", blushDeep:"#c89a8d", ink:"#2e342e", inkSoft:"#5b635c", inkMute:"#8a8f88" },
  blush:   { cream:"#f8efe9", creamSoft:"#fbf4ef", creamDeep:"#f0e3da", sage:"#c89a8d", sageDeep:"#a87568", sageSoft:"#ecd2c7", blush:"#d8a89a", blushDeep:"#a87568", ink:"#3a2e2c", inkSoft:"#6e5c58", inkMute:"#9c8a85" },
  cool:    { cream:"#eef1f3", creamSoft:"#f6f8fa", creamDeep:"#dde3e7", sage:"#8aa2b0", sageDeep:"#5d7c8d", sageSoft:"#c5d2da", blush:"#d8c4cc", blushDeep:"#a98ea0", ink:"#2a3138", inkSoft:"#566069", inkMute:"#8a939c" },
  mono:    { cream:"#f4f1ec", creamSoft:"#faf8f4", creamDeep:"#e6e2da", sage:"#5b635c", sageDeep:"#2e342e", sageSoft:"#c0c2bd", blush:"#c0c2bd", blushDeep:"#5b635c", ink:"#1a1d1a", inkSoft:"#4a4f49", inkMute:"#888c85" },
};

const TYPE_PAIRS = {
  "fraunces-quicksand": { display:'"Fraunces", Georgia, serif', sans:'"Quicksand", ui-rounded, system-ui, sans-serif' },
  "fraunces-inter":     { display:'"Fraunces", Georgia, serif', sans:'"Inter", system-ui, sans-serif' },
  "all-quicksand":      { display:'"Quicksand", ui-rounded, system-ui, sans-serif', sans:'"Quicksand", ui-rounded, system-ui, sans-serif' },
  "newsreader-nunito":  { display:'"Newsreader", Georgia, serif', sans:'"Nunito", system-ui, sans-serif' },
};

function applyTweaks(t){
  const p = PALETTES[t.palette] || PALETTES.sage;
  const r = document.documentElement.style;
  r.setProperty("--cream", p.cream);
  r.setProperty("--cream-soft", p.creamSoft);
  r.setProperty("--cream-deep", p.creamDeep);
  r.setProperty("--sage", p.sage);
  r.setProperty("--sage-deep", p.sageDeep);
  r.setProperty("--sage-soft", p.sageSoft);
  r.setProperty("--blush", p.blush);
  r.setProperty("--blush-deep", p.blushDeep);
  r.setProperty("--ink", p.ink);
  r.setProperty("--ink-soft", p.inkSoft);
  r.setProperty("--ink-mute", p.inkMute);

  const pair = TYPE_PAIRS[t.typePairing] || TYPE_PAIRS["fraunces-quicksand"];
  r.setProperty("--font-display", pair.display);
  r.setProperty("--font-sans", pair.sans);

  const head = document.querySelector(".display");
  if(head && t.heroHeadline){
    // turn first word into emphasized via simple parse: we keep the existing markup but allow override
    head.innerHTML = t.heroHeadline.replace(/\b(calm|gentle|quiet|simple)\b/i, '<em>$1</em>');
  }
  const lede = document.querySelector(".hero-text .lede");
  if(lede && t.heroLede) lede.textContent = t.heroLede;

}

function App(){
  const [tweaks, setTweak] = useTweaks(TWEAK_DEFAULTS);

  useEffect(()=>{ applyTweaks(tweaks); }, [tweaks]);

  // ensure additional Google fonts load if user picks them
  useEffect(()=>{
    const need = (tweaks.typePairing === "newsreader-nunito");
    if(need && !document.getElementById("extra-fonts")){
      const link = document.createElement("link");
      link.id = "extra-fonts";
      link.rel = "stylesheet";
      link.href = "https://fonts.googleapis.com/css2?family=Newsreader:ital,opsz,wght@0,6..72,300;0,6..72,400;1,6..72,300&family=Nunito:wght@400;500;600;700&display=swap";
      document.head.appendChild(link);
    }
    if(tweaks.typePairing === "fraunces-inter" && !document.getElementById("inter-font")){
      const link = document.createElement("link");
      link.id = "inter-font";
      link.rel = "stylesheet";
      link.href = "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap";
      document.head.appendChild(link);
    }
  }, [tweaks.typePairing]);

  return (
    <TweaksPanel title="Tweaks">
      <TweakSection title="Palette">
        <TweakRadio
          value={tweaks.palette}
          onChange={v=>setTweak("palette", v)}
          options={[
            {value:"sage",  label:"Sage"},
            {value:"blush", label:"Blush"},
            {value:"cool",  label:"Cool"},
            {value:"mono",  label:"Mono"},
          ]}
        />
      </TweakSection>

      <TweakSection title="Type pairing">
        <TweakSelect
          value={tweaks.typePairing}
          onChange={v=>setTweak("typePairing", v)}
          options={[
            {value:"fraunces-quicksand", label:"Fraunces × Quicksand (default)"},
            {value:"fraunces-inter",     label:"Fraunces × Inter"},
            {value:"all-quicksand",      label:"Quicksand only"},
            {value:"newsreader-nunito",  label:"Newsreader × Nunito"},
          ]}
        />
      </TweakSection>

      <TweakSection title="Hero copy">
        <TweakText
          label="Headline"
          value={tweaks.heroHeadline}
          onChange={v=>setTweak("heroHeadline", v)}
        />
        <TweakText
          label="Lede"
          multiline
          value={tweaks.heroLede}
          onChange={v=>setTweak("heroLede", v)}
        />
      </TweakSection>

      <TweakSection title="Hero copy">
    </TweaksPanel>
  );
}

const root = document.createElement("div");
root.id = "tweaks-root";
document.body.appendChild(root);
ReactDOM.createRoot(root).render(<App/>);
