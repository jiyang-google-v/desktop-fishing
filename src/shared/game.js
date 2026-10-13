const fish = require('./fish-data.json');
const MAX_DEPTH = 200, DEPTH_PER_SECOND = 4/60, IDLE_LIMIT_SECONDS = 600;
const rarityWeight = { common: 60, uncommon: 25, rare: 9, legendary: 1 };
function depthFor(seconds) { return Math.min(MAX_DEPTH, Math.max(0, seconds) * DEPTH_PER_SECOND); }
function canAccrue({cast, foreground, locked, sleeping, idleSeconds, supported}) {
  return Boolean(cast && supported && !foreground && !locked && !sleeping && Number.isFinite(idleSeconds) && idleSeconds >= 0 && idleSeconds <= IDLE_LIMIT_SECONDS);
}
function eligibleFish(depth, isNight, roster=fish) {
  return roster.filter(f => depth >= f.minDepth && depth <= f.maxDepth && (f.time !== 'night' || isNight));
}
function pickFish(depth, isNight, random=Math.random, roster=fish) {
  const choices = eligibleFish(depth, isNight, roster);
  if (!choices.length) return null;
  const weights = choices.map(f => rarityWeight[f.rarity] || 1);
  const total = weights.reduce((a,b)=>a+b,0);
  let roll = Math.max(0, Math.min(0.999999999, random())) * total;
  for(let i=0;i<choices.length;i++) { roll -= weights[i]; if(roll<0) return choices[i]; }
  return choices[choices.length-1];
}
function addToAquarium(aquarium, id) { if(aquarium.length>=6) return {ok:false,reason:'full',aquarium}; return {ok:true,aquarium:[...aquarium,id]}; }
module.exports={fish,depthFor,canAccrue,eligibleFish,pickFish,addToAquarium};
