# Supervisor Loop — Orchestrazione a strati ("scatole cinesi") per il software development end-to-end

> Companion operativo di `GOAL-LOOP-PLAYBOOK.md`.
> Qui l'unità di annidamento **non è un gate**, è **un loop intero** (Goal + Worker +
> Verifier indipendente + Stop + Memoria). La scatola cinese è: *un loop che scrive loop
> che scrivono loop*, con l'invariante che si ripete a ogni strato —
> *"completion is decided by a fresh model rather than the one doing the work"* — **ricorsivamente**.
> Fonti del concetto: `goal&loop.md` (Cherny: *"continuous orchestration loop that oversees
> other threads/agents"*, *"My job is to write loops"*) + i 5 componenti del playbook §0.

---

## 0. Perché loop e non gate

Una checklist lineare di gate (G0…G9) è ancora *un solo loro* che attraversa stati. L'orchestrazione
vera è **tra strati**: un loop di controllo che sorveglia altri loop. Il salto di livello
(`goal&loop.md`, righe 49-53): *"It's not ralph/goal loops, that's old hat… it's some kind of
continuous orchestration loop that oversees other threads/agents."*

L'orchestrazione non è la sequenza delle fasi — è **l'handshake tra gli strati**: cosa L0 passa
giù (il contratto del loop), cosa L1 restituisce su (verdetto + evidenza), cosa innesca un retry
vs un avanzamento vs un halt.

---

## 1. Architettura: 3 strati, ognuno un loop completo

```
L0  SUPERVISOR LOOP  — "il loop che scrive loop". NON scrive codice.
    CEO · Strategist · Auditor · Resource Allocator · Risk Manager.
    Per tick: assess → dispatcha UN loop operativo → legge il verdetto → distilla in memoria → instrada.
    │  contratto ↓ passa {goal, worker-spec, verifier indipendente, stop}
    │  contratto ↑ riceve {verdict + evidence-in-transcript, delta di memoria}
    └─ L1  OPERATIONAL LOOP  — un goal-loop autonomo per workstream, stampato da un template.
       │  ha il SUO verifier indipendente (≠ il suo worker).
       │  contratto ↓ il worker può fare fan-out
       │  contratto ↑ verdetto operativo
       └─ L2  WORKER FAN-OUT + SELF-VERIFY — dentro un loop: subagent per offload
          (Ralph: ammessi *dentro* un'iterazione), reviewer fresco per la second-opinion,
          browser MCP per l'auto-verifica end-to-end. Anche qui il giudice ≠ chi lavora.
```

### Mappa sul "sistema a 5 loop (SOTA 2026)" dell'infografica

| Cerchio infografica | Strato | Ruolo |
|---|---|---|
| **Supervisor Loop** (centro) | L0 | Orchestra, alloca, valuta rischi, ferma. Non implementa. |
| **Architecture Loop** | L1 | Esplora soluzioni, trade-off, challenge, rischi, documenta. |
| **Coding Loop** | L1 | Select → implement → compile → test → fix&refactor → repeat. |
| **Verification Loop** | L1 + L2 | "Assumi sia tutto rotto": avversariale, mutation, browser MCP. |
| **Memory Loop** | pervasivo (ogni tick) | fail→investigate→verify→distill→consult. |
| **Meta-Reflection Loop** | periodico (L0) | Migliora i loop stessi: fix permanente di prompt/spec/tooling. |

---

## 2. ① SUPERVISOR LOOP (il centro — orchestra, non implementa)

```
/loop   (self-paced — you are the SUPERVISOR LOOP: CEO · Strategist · Auditor · Resource
         Allocator · Risk Manager. You orchestrate other loops; you do NOT write code
         except in exceptional cases.)

MISSION — ship feature <NAME>, verified. You never implement directly. Each tick you assess
the system, dispatch EXACTLY ONE operational loop (ARCHITECTURE | CODING | VERIFICATION),
fold its verdict into the Memory Loop, and decide what's next. You run the Meta-Reflection
Loop periodically to improve the loops themselves. You halt when the feature is
verified-shipped or a hard stop fires — making the loops stop is your real job.

BOOTSTRAP (tick 0 — human in the loop) — run INTAKE: interview the user for name+JTBD, spec,
LOOK-ALIKES (urls + what to match/avoid), STACK, repo SKILLS/PLUGINS to compose, the BROWSER
MCP for self-verify (`claude mcp list`; if absent add `chrome-devtools` via
`npx -y chrome-devtools-mcp@latest`, or Playwright MCP), checks, scope/legal, budgets. Write
docs/feature/<NAME>/PROJECT.md, echo it, WAIT for the user's CONFIRMED. Dispatch nothing until
confirmed.

STATE  docs/feature/<NAME>/ORCHESTRATION.md — workstream ledger + budget counter.
MEMORY docs/feature/<NAME>/MEMORY.md — the Memory-Loop store (cross-session).
RULES  docs/feature/<NAME>/META.md — the Meta-Reflection rules (how the loops should run).

TICK BODY — the 7 supervisor moves (your "ogni ciclo"):
  1. STATE       — read PROJECT.md + the ledger.
  2. WORKSTREAMS — review what the last operational loop returned (verdict + evidence).
  3. MEMORY      — CONSULT MEMORY.md + META.md; never re-derive a settled rule.
  4. PROGRESS    — no-progress check: two ticks, no diff on a workstream ⇒ flag.
  5. RISK        — as Risk Manager, name what could compound (bad commit, runaway cost).
  6. QUALITY     — as Auditor, confirm the last verdict was backed by REAL adversarial
                   evidence pasted in the transcript — not the worker's self-approval.
  7. DECIDE      — dispatch the single next operational loop (default per feature:
                   ARCHITECTURE → CODING → VERIFICATION, looping CODING↔VERIFICATION per
                   story), OR run META-REFLECTION, OR HALT.

DISPATCH — instantiate the chosen loop from the OPERATIONAL TEMPLATE, handing it
{goal, worker-spec, INDEPENDENT verifier, stop} from its CATALOG row. You are its
environment: you feed it feedback, you never do its work.

MEMORY LOOP (every tick) — append to MEMORY.md: FAIL (what broke) → INVESTIGATE (why) →
VERIFY (the checked fact) → DISTILL (the general rule). Goal: intelligence that compounds.

META-REFLECTION LOOP (every 5 ticks, or whenever a failure domain repeats) — do NOT tolerate
a recurring failure: fix it PERMANENTLY in the prompt/spec/tooling and write the fix to
META.md so the next dispatch inherits it. Goal: improve how the loops run, not just the code.

RECURSION INVARIANT — at every layer the judge ≠ the worker: you are judged "verified-shipped"
by a fresh final verifier; each operational loop by its own; the Verification loop spawns fresh
adversarial subagents. No self-promotion, ever.

HARD STOPS — MAX 200 ticks / 4 retries per workstream; NO-PROGRESS two ticks no diff ⇒ halt &
report; BUDGET stop at <time/token ceiling>.
```

---

## 3. ② OPERATIONAL-LOOP TEMPLATE (la scatola che il Supervisor stampa)

```
/goal Operational loop <L.name> for feature <NAME> reached its goal: <L.goal>. WORKER:
<L.worker> — high effort, full task first turn; reads PROJECT.md + MEMORY.md + META.md first;
may fan out subagents for context offload; uses a FRESH context for any judging. INDEPENDENT
VERIFIER: a fresh evaluator decides from the transcript ONLY — paste <L.evidence> or it does
not close. CONSTRAINTS (anti reward-hack): <L.guards>. Append FAIL→INVESTIGATE→VERIFY→DISTILL
to MEMORY.md on failure. Return the verdict to the Supervisor. Or stop after <L.cap> turns and
report 'blocked'.
```

---

## 4. ③ I 4 LOOP OPERATIVI (i parametri che il Supervisor inietta nel template)

| loop | goal (slide 5) | worker (repo skill) | evidence (paste) | guards | cap |
|---|---|---|---|---|---|
| **ARCHITECTURE** | un'architettura **solida, scalabile, giustificata**: esplora ≥2 opzioni, analizza trade-off, *challenge* il design, identifica i rischi, documenta in `ARCHITECTURE.md` | `nw-design` / solution-architect | la tabella opzioni + la scelta-con-rationale + la lista rischi | nessuna implementazione qui; ogni claim legato a un requisito di PROJECT.md | 20 |
| **CODING** | codice **funzionante, semplice, manutenibile** per la singola prossima story: select → implement test-first → compile → test → fix&refactor → repeat; test FAIL pre-impl & PASS post; `npm test` 0 no skip; `npm run check` 0; nessun file in scope >300 righe | `nw-execute` / software-crafter, **una story per spawn** (Ralph) | ENTRAMBI red e green output + `wc -l` | mai editare assertion; no .skip/.only; non abbassare coverage; refactor behavior-preserving | 40/story |
| **VERIFICATION** | **zero difetti significativi, alta confidenza**: *assumi che sia tutto rotto* — caccia bug/edge-case/vulnerabilità, test avversariali + mutation, guida il prodotto live via **browser MCP**, approva SOLO con evidenza forte | reviewer **fresco** su `git diff main...HEAD` + `code-review`/`security-review` + mutation + browser MCP | una 2ª pass fresca = zero correctness findings + tabella mutation ≥ soglia + transcript browser-MCP (200 + flow OK) | correttezza/sicurezza non stile; **mai indebolire un check** per farlo passare; mai editare la CI per saltare uno step rosso | 25 |
| **MEMORY** | *(pervasivo, ogni tick — non si dispatcha)* intelligenza che **si compone nel tempo** | il Supervisor stesso | — fail→investigate→verify→distill→consult — | — | — |

---

## 5. Mappatura strato → primitiva reale

È questo che rende l'orchestrazione concreta e non da poster:

- **Supervisor Loop** = `/loop` self-paced (sceglie la cadenza, si auto-termina).
  *Caveat onesto dal playbook:* il valutatore `/goal` è transcript-only e non può spawnare —
  il Supervisor è un `/loop`/thread, **oppure sei tu** che "scrivi loop".
- **Architecture / Coding** = `/goal` (valutatore **Opus 4.8** — override di progetto, vedi §10)
  o **CMA Outcome** (grader sub-agent) per i run lunghi.
- **Verification** = `/goal` + **L2 fan-out**: subagent avversariale fresco (gate-4
  second-opinion) + mutation + browser MCP per il self-verify end-to-end (Cherny tip 5).
- **Memory Loop** = lo store cross-sessione (playbook §5).
- **Meta-Reflection** = il fix permanente di Huntley (*"resolve it so it never happens again"*),
  reso istruzione per il modello.

---

## 6. ⚠️ Verificato vs sintetizzato (disciplina del playbook)

- **Spina dorsale — verificata ✅:** i 5 componenti del loop, l'invariante judge≠worker
  ricorsivo, `/goal` · `/loop` · CMA Outcomes, i 3 hard-stop, skills+loops, Ralph "one thing".
- **Nomenclatura — sintesi 🔧:** "sistema a 5 loop / Supervisor / Meta-Reflection" è
  un'architettura di lavoro coerente ma **non** una fonte primaria (come "Gas Town"): usala
  come framework operativo, non citarla come fatto SOTA 2026.
- **Niente "centinaia/migliaia di agenti"** (smentito 1-2 nel playbook): il fan-out L2 resta
  **misurato**.
- **Dettagli Gas Town** (Mayor/patrol) non hanno superato la verifica: si usa solo il *pattern*
  "continuous orchestration loop che sorveglia thread", non quei dettagli come fatti.

---

## 7. I tre hard stop, allo strato Supervisor

| Hard stop | Implementazione L0 |
|---|---|
| **Max iterazioni** | MAX 200 ticks / 4 retry per workstream nel TICK BODY |
| **No-progress detection** | due tick senza diff su un workstream ⇒ `blocked` + surface all'umano |
| **Budget ceiling** | clausola tempo/token nel prompt; cap 50 task schedulati/sessione |

Promemoria di umiltà (playbook §6): i guardrail **limitano, non eliminano** (issue #55754: quota
bruciata in ~50 min). Loop nuovo ⇒ prima supervisionato, poi walk-away.

---

## 8. Come girarlo davvero (skills + loops, playbook §7)

Impacchetta, non incollare prompt ad-hoc lunghi:

- **`/supervise-feature`** = il Supervisor Loop (L0) come skill.
- **`/op-loop`** = il template operativo (L1) come skill parametrizzata.
- Lancio: `/loop /supervise-feature` (self-paced). Per i run multi-agente vale la regola del
  CLAUDE.md: ogni teammate nel proprio worktree, merge orchestrato alla fine.

> *I prompt dicono agli agenti cosa fare. I loop li aiutano a capire **cosa fare dopo**.*
> Il Supervisor è proprio quel "cosa-fare-dopo".

---

## 9. Variante: TUTTO in un singolo `/goal` (loop operativi innestati internamente)

Stessa architettura, ma collassata in **una sola goal-condition**. Cambio di meccanica: il
valutatore `/goal` (**Opus 4.8** nel nostro setup, §10) è transcript-only e **non può spawnare
loop** → i loop operativi
diventano un **protocollo interno** che il worker esegue *dentro ogni turno*. L'indipendenza
del giudice (judge≠worker) si ottiene perché **il worker spawna subagent freschi** per la
Verification *dentro* il turno; il `/goal` evaluator è il **giudice fresco più esterno** sul
transcript. Precondizione: `PROJECT.md` già compilato e CONFIRMED (esegui prima l'INTAKE /goal).

```
/goal Feature <NAME> is verified-shipped. ONE measurable end state: every operational loop
below reports SATISFIED with its evidence pasted in THIS conversation. A fresh evaluator reads
the transcript only and runs no tools — an unproven loop never counts. You are the SUPERVISOR:
you orchestrate the nested loops, you do not free-code. Read docs/feature/<NAME>/PROJECT.md +
MEMORY.md before each turn; never re-derive a settled rule.

EACH TURN = one supervisor cycle over the NESTED operational loops:
  ROUTE — pick the single next loop whose predecessors are satisfied (order ARCHITECTURE →
  CODING → VERIFICATION, cycling CODING<->VERIFICATION per story). One loop per turn.

  > ARCHITECTURE LOOP (nested) — explore >=2 options, analyze trade-offs, identify risks,
    document the chosen design + rationale in docs/feature/<NAME>/ARCHITECTURE.md. SATISFIED:
    paste the options table + chosen-with-rationale + risk list. GUARD: no code here; every
    claim tied to a PROJECT.md requirement.

  > CODING LOOP (nested, one story/turn) — for the single next story: tests that FAIL before
    and PASS after; implement; `npm test` exits 0 no skips; `npm run check` exits 0; no in-scope
    file >300 lines. SATISFIED: paste BOTH the red and the green output + `wc -l`. GUARD: never
    edit existing assertions; no .skip/.only; don't lower coverage; refactor behavior-preserving.

  > VERIFICATION LOOP (nested, ADVERSARIAL) — assume it's all broken. Spawn a FRESH reviewer
    subagent seeing ONLY `git diff main...HEAD` + criteria (correctness, contracts, security,
    parity vs PROJECT.md look-alikes); run mutation tests; drive the live preview via the
    browser MCP. Each finding: fix or refute with pasted evidence. SATISFIED: paste a 2nd
    fresh-subagent pass = zero correctness findings + mutation table >= threshold + browser-MCP
    transcript (200 + key flow OK). GUARD: correctness/security not style; never weaken a check
    or edit CI to skip a failing step.

  MEMORY LOOP (every turn) — append to MEMORY.md: FAIL -> INVESTIGATE -> VERIFY -> DISTILL for
  anything that broke. META-REFLECTION (when a failure domain repeats) — fix it permanently in
  the spec/prompt/tooling and record it so the next turn inherits the fix.

RECURSION INVARIANT — the judge is never the worker: the Verification loop uses fresh spawned
subagents; this whole goal is closed by the fresh evaluator, never by your self-approval.

DONE only when ARCHITECTURE + every story's CODING + VERIFICATION are all SATISFIED with
evidence in the transcript, and every [TO CONFIRM] in PROJECT.md is resolved. Constraints: edit
only under the feature's paths. NO-PROGRESS: if two turns produce no diff, stop and report the
blocking loop. Or stop after 120 turns.
```

**Differenza chiave vs la versione multi-primitiva (§2-4):**

| | Supervisor `/loop` + `/goal` figli (§2-4) | Singolo `/goal` innestato (§9) |
|---|---|---|
| Strati | loop reali che spawnano loop reali | un loop, loop operativi come protocollo interno al turno |
| Verifier per fase | un `/goal` evaluator per fase | un solo evaluator finale + subagent freschi spawnati dal worker |
| Quando usarlo | run lunghi, workstream paralleli, walk-away | feature singola, tutto in una sessione, ≤4000 char |
| Limite | nessuno (prompt `/loop`) | la condizione deve stare in 4000 char |

Entrambi rispettano l'invariante judge≠worker; cambia solo **dove** vive l'indipendenza del
giudice (primitive separate vs subagent spawnati dentro il turno).

---

## 10. Modello del valutatore: Opus 4.8 (non Haiku) — decisione di progetto

Decisione: in questo repo il valutatore di completamento di `/goal` è **Opus 4.8**
(`claude-opus-4-8`), non il default Haiku.

**Perché.** Le nostre goal-condition sono multi-criterio e avversariali (la Verification
"assumi sia tutto rotto", parità vs look-alike, anti reward-hack). Un giudice più capace:
- segue rubriche sfumate senza approvare per "vibes";
- è più difficile da ingannare con evidenza parziale o test tautologici;
- emette verdetti di Verification più affidabili (il punto dove un giudice debole costa caro).

**Come si configura** (verificato sui docs ufficiali — `goal.md` + `hooks.md`). `/goal` è un
wrapper attorno a uno **Stop hook a prompt session-scoped**, e gli hook a prompt accettano un
campo `model`. In `.claude/settings.json` (scope di progetto):

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "goal",
        "hooks": [
          { "type": "prompt",
            "prompt": "Does the goal condition hold? $ARGUMENTS",
            "model": "claude-opus-4-8" }
        ]
      }
    ]
  }
}
```

> ⚠️ Valida l'esatto `matcher`/wiring contro i docs della tua versione installata
> (`node_modules` o code.claude.com/docs/en/hooks.md): il *campo* `model` sugli hook a prompt è
> documentato; il modo in cui `/goal` lo eredita va confermato sulla tua build. Non esiste flag
> CLI né env var dedicata al valutatore di `/goal` (`ANTHROPIC_DEFAULT_HAIKU_MODEL` governa il
> small-fast model di background, non questo).

**Cosa NON cambia (regola più importante del playbook).** Anche con Opus 4.8 il valutatore
resta **transcript-only**: *"It does not call tools, so it can only judge what Claude has
already surfaced in the conversation."* Un modello più forte **non** acquisisce accesso ai tool
→ la disciplina **evidence-in-transcript** (`paste the output…`) resta obbligatoria, non
rilassabile.

**Costo/latenza.** La valutazione gira **dopo ogni turno**. I docs la danno "typically
negligible" *sul small-fast model*; con Opus 4.8 il costo per-turno sale e si **compone** sui
nostri cap da 120-200 turni. Contromisure: tieni i cap di turni stretti; valuta Opus 4.8 dove la
decisione è sfumata (Architecture/Verification) e lascia il default leggero dove la condizione è
banale e deterministica (es. `npm run check exits 0` puro).

**Diversità di modello.** Con worker Opus 4.8 + valutatore Opus 4.8 l'indipendenza viene dal
**contesto fresco**, non dalla diversità di modello (Parameter Golf: il contesto indipendente
basta a battere la self-critique). Per la Verification L2 un subagent avversariale forte
(Opus 4.8 fresh-context) è esattamente ciò che serve per trovare bug reali.
