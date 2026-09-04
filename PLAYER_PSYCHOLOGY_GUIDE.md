# PrisMaze Player Psychology Guide
## Ethical Engagement Design

> ⚠️ **Ethics First**: These patterns should enhance enjoyment, not exploit vulnerabilities. 
> Always ask: "Would I be proud to explain this to players?"

---

## 🔄 Engagement Loop (Ethical Implementation)

### The Hook Model (Nir Eyal, adapted ethically)

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   TRIGGER   │ ──▶ │   ACTION    │ ──▶ │   REWARD    │ ──▶ │ INVESTMENT  │
│ Level done! │     │ Start next  │     │ Stars/Tokens│     │ Time spent  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
        ▲                                                           │
        └───────────────────────────────────────────────────────────┘
```

### Variable Rewards (Healthy Surprise)
| Reward Type | Frequency | Example |
|---|---|---|
| Expected | 100% | Stars based on moves |
| Bonus | 30% | Extra tokens for speed |
| Rare | 5% | Skin unlock notification |
| Ultra Rare | 1% | Secret achievement |

**Ethical Boundary**: Never use gambling mechanics. Rewards are skill-based, not random.

---

## 📊 Progress Psychology

### Near-Goal Motivation
```dart
// Show "almost there" messages at key thresholds
if (starsToNextSkin <= 15) {
    showMessage("Bir sonraki skin'e sadece $starsToNextSkin yıldız!");
}
```

### Completion Drive (Endowed Progress Effect)
- "10 level'dan 7'sini tamamladın!" → User feels 70% done
- Show progress as fraction, not just number
- Visual progress bars increase perceived investment

### Implementation Points:
- World completion percentage
- Daily mission progress
- Achievement progress bars
- Star collection milestones

---

## 😰 Loss Aversion (Light Touch Only)

### Acceptable Uses:
| Pattern | Message | Ethicality |
|---|---|---|
| Daily bonus reminder | "Günlük bonusun bekliyor!" | ✅ Informative |
| Streak celebration | "7 günlük seri!" | ✅ Achievement |
| Gentle nudge | "Yarın da gel, seri devam etsin" | ✅ Encouraging |

### What We DON'T Do:
- ❌ Aggressive countdown timers
- ❌ "You'll LOSE everything!" language
- ❌ Punishing missed days harshly
- ❌ Dark patterns that guilt trip

### Streak System Design:
- Breaking streak only resets BONUS multiplier, not all progress
- Player can use 1 free "streak freeze" per week
- Returning after break gets "Welcome back!" reward

---

## 🧠 Zeigarnik Effect (Unfinished Business)

### Why It Works:
- Incomplete tasks stay in working memory
- Player thinks about puzzle when away
- Creates natural desire to return

### Design Support:
1. **Mid-Level Save**: Auto-save after every move
2. **Resume Prompt**: "Yarım kalan level'ı sürdür?"
3. **Visual Reminder**: Incomplete level shows on menu with ⏸️ icon
4. **Low Friction**: One tap to resume exactly where left

### Already Implemented:
- `LevelStateManager` auto-saves position
- Resume state restored on app launch

---

## ⏰ FOMO (Fear of Missing Out)

### Ethical Limited-Time Events:
| Event Type | Duration | Recurrence | Notes |
|---|---|---|---|
| Daily Challenge | 24h | Daily | Always available daily |
| Weekly Special | 7 days | Weekly | Different theme each week |
| Seasonal Event | 2 weeks | Quarterly | Halloween, New Year, etc. |

### Boundaries:
- ✅ Cosmetic rewards only (skins, effects)
- ✅ Events repeat/return eventually
- ✅ Core gameplay never locked behind events
- ❌ No exclusive "never again" items
- ❌ No pay-to-skip event timers

### Messaging:
```
✅ "Özel skin bu hafta mevcut!"
❌ "SADECE BUGÜN! BU FIRSATI KAÇIRMA!"
```

---

## 💡 Positive Reinforcement Patterns

### Celebration Design:
- 3-star completion: Confetti + sound + screen shake
- Level milestone (10, 25, 50): Special animation
- Achievement unlock: Toast + token reward
- Streak milestone: Badge + celebration screen

### Encouragement After Failure:
- "Çok yaklaştın! Tekrar dene?"
- "İpucu kullanmak ister misin?"
- Never: "Başarısız oldun" or negative language

---

## 📋 Implementation Checklist

- [x] Variable reward system (stars, tokens, achievements)
- [x] Progress bars in UI (stats screen)
- [x] Daily login rewards (EconomyManager)
- [x] Streak tracking (EconomyManager)
- [x] Mid-level auto-save (LevelStateManager)
- [x] Achievement system (ProgressManager)
- [ ] Limited-time event framework
- [ ] "Welcome back" reward system
- [ ] Streak freeze mechanic

---

## 🎯 Key Metrics to Monitor

| Metric | Healthy Range | Concern If |
|---|---|---|
| Session Length | 5-15 min | >30 min consistently |
| Sessions/Day | 2-4 | >8 (addiction risk) |
| Day-1 Retention | 40%+ | Below 30% |
| Day-7 Retention | 20%+ | Below 10% |
| IAP Spend/User | $0-10 | Whale patterns |

> **If metrics show addictive patterns, we intervene with "Take a break" prompts.**

---

*"Oyuncuların eğlenmesini sağla, sömürülmesini değil."*
