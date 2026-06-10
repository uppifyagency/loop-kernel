# Loop Engineering Playbook — Goal & Loop prompts per ogni fase del code development

> Costruito il 2026-06-10 da una deep research multi-fonte con verifica avversariale
> (104 agenti, 22 fonti primarie, 25 claim verificati → 23 confermati 3-0, 2 smentiti)
> incrociata con la documentazione ufficiale Claude API / Claude Code.
> Le fonti sono in fondo. I prompt sono in inglese (più portabili e meglio seguiti dai modelli);
> la guida è in italiano.

---

## 0. TL;DR

Il "loop engineering" è il passaggio da *scrivere prompt* a *progettare i sistemi di controllo
che promptano gli agenti*. La versione romantica è "mille agenti costruiscono l'azienda di notte";
la versione di produzione è: **scrivi i loop, e gran parte del lavoro è assicurarti che si fermino**.

Ogni loop ben progettato ha 5 componenti:

1. **Goal** — uno stato finale misurabile (non "fai un buon lavoro": "il check X esce 0")
2. **Worker** — il modello che lavora (task spec completa nel primo turno, effort alto)
3. **Verifier indipendente** — chi giudica NON è chi lavora (contesto separato)
4. **Stopping conditions** — i 3 hard stop: max iterazioni, no-progress detection, budget ceiling
5. **Memoria** — l'outer loop tra sessioni: fail → investigate → verify → distill → consult

---

## 1. Cosa è verificato (e cosa no)

La ricerca ha verificato ogni claim con 3 voti avversariali indipendenti contro le fonti primarie.
Risultati chiave — **tutti confermati 3-0 sul testo originale**:

### I 5 tips di Boris Cherny (8 giugno 2026, X + Threads)
Per far girare Claude autonomo per ore/giorni:
1. **Auto mode** per i permessi (niente richieste di approvazione)
2. **Dynamic workflows** per orchestrare agenti
3. **`/goal` o `/loop`** — *"to nudge Claude to keep going until it's done"*
4. **Claude Code in the cloud** — così puoi chiudere il laptop
5. **Self-verify end-to-end** — *"Claude in Chrome browser extension for web, iOS/Android sim
   MCP for mobile, a way to start the full web server or service for backend work"*

Cherny chiama `/loop` e `/schedule` *"two of the most powerful features in Claude Code"* e fa
girare in locale: `/loop 5m /babysit` (auto-risponde ai commenti di review e auto-rebase delle PR),
`/loop 30m /slack-feedback` (apre PR dal feedback Slack), `/loop 1h /pr-pruner`.
La sua raccomandazione esplicita: **"turning workflows into skills + loops"** — i loop invocano
workflow impacchettati (skill), non prompt ad-hoc.

### Le meccaniche ufficiali di `/goal` (docs verificate live il 2026-06-10)
- `/goal` è un wrapper attorno a uno **Stop hook a prompt, session-scoped**: dopo ogni turno,
  la condizione + la conversazione vengono mandate a un **modello piccolo e veloce (default Haiku)**
  che risponde sì/no + motivo. Un "no" fa ripartire un altro turno **con il motivo come guida**.
- Principio architetturale documentato: *"completion is decided by a fresh model rather than
  the one doing the work"* — il worker non si auto-promuove.
- ⚠️ **Il valutatore non può usare tool** — giudica SOLO il transcript. Conseguenza operativa
  (la regola più importante di questo playbook): la condizione deve chiedere che **l'evidenza
  appaia nella conversazione** ("paste the test output"), altrimenti il valutatore non può decidere.
- Condizioni fino a **4.000 caratteri**.

### `/goal` vs `/loop` (tabella ufficiale, verificata verbatim)

| | Il turno successivo parte quando… | Si ferma quando… |
|---|---|---|
| **`/goal`** | il turno precedente finisce | un modello conferma che la condizione è soddisfatta |
| **`/loop`** | scade un intervallo di tempo (cron, min 1 minuto) | lo fermi tu, o Claude decide che il lavoro è finito |

- `/loop` **self-paced** (intervallo omesso): Claude sceglie il delay (1 min – 1 ora) in base a
  ciò che ha osservato, e può **terminare il loop da solo non schedulando il prossimo wakeup**
  quando il task è provabilmente completo.
- `/loop` **a intervallo fisso**: NON si auto-termina — gira finché non lo fermi o scade.

### Guardrail anti-runaway documentati
- **Stop hook**: Claude Code fa override e chiude il turno dopo **8 blocchi consecutivi senza
  progresso** (default configurabile via `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP`).
- **Scadenza 7 giorni**: i task ricorrenti session-scoped si auto-cancellano dopo 7 giorni —
  *"This bounds how long a forgotten loop can run"*. (Le routine cloud `/schedule` persistono.)
- **Cap di 50 task schedulati** per sessione.
- I guardrail **limitano ma non eliminano** gli incidenti di costo: l'issue
  anthropics/claude-code#55754 documenta uno Stop-hook loop di ~50 minuti che ha bruciato
  un'intera quota di sessione.

### Ralph loop (Geoffrey Huntley — l'antenato community della tecnica)
- Forma più pura: `while :; do cat PROMPT.md | claude-code ; done`
- Disciplina operativa: **un solo task per iterazione** ("Only one thing") perché il contesto
  utilizzabile è limitato (~170k token, snapshot 2025) — il context window è una *allocazione
  di memoria* riempita identicamente a ogni giro dalle spec di backing.
- Verifica: **back pressure automatica** (test, type system, compilazione) per il codice
  generato + **operatore umano che guarda il loop**: *"When you see a failure domain — put on
  your engineering hat and resolve the problem so it never happens again"* (fix permanente di
  prompt/spec/tooling, non tolleranza del fallimento ripetuto).
- Architettura **deliberatamente monolitica** (un processo, un repo); il multi-agent è liquidato
  come "red hot mess" (subagent paralleli ammessi *dentro* un'iterazione per offload di contesto).
- La tecnica è stata assorbita nel tooling ufficiale: plugin `ralph-wiggum` in anthropics/claude-code.

### CMA Outcomes (l'equivalente API di `/goal`, dalla doc ufficiale)
- Evento `user.define_outcome` con **rubrica obbligatoria** (testo o file) e `max_iterations`
  (default 3, max 20). Un **grader sub-agent in contesto indipendente** valuta ogni iterazione:
  `satisfied` / `needs_revision` / `max_iterations_reached` / `failed` / `interrupted`.
- Regola di scrittura della rubrica: criteri **espliciti e gradabili indipendentemente**
  ("CSV has a numeric `price` column"), non vibes ("data looks good"). Se non hai una rubrica:
  fai analizzare a Claude un artefatto noto-buono e trasforma l'analisi in rubrica.
- Il verifier sub-agent **supera la self-critique** perché il grading avviene in un context
  window indipendente (esperimento Parameter Golf, Lance Martin / Anthropic).

### ❌ Cosa NON citare (smentito o non trovato)
- La **"three-stage definition of loops" di Cherny non esiste come fonte primaria** — è
  mitologia da commento secondario (l'articolo Medium). Sopravvivono solo i 5 tips e il post
  /loop+/schedule.
- **Gas Town di Steve Yegge**: zero claim sopravvissuti alla verifica. Il repo e il post Medium
  esistono, ma i dettagli circolanti (Mayor agent, patrol agents, 20-30 istanze) non sono stati
  confermati da questa ricerca — non darli per assodati.
- Il framing "Cherny raccomanda centinaia/migliaia di sub-agenti" è **smentito** (1-2): il tip
  sui dynamic workflows va citato senza quella scala.
- Il framing "fix_plan.md è la stopping condition di Ralph" è **smentito** (1-2).

---

## 2. Le regole per scrivere una goal condition

Rubrica ufficiale (docs `/goal`) + integrazioni verificate. Una condizione durevole ha:

1. **Un solo stato finale misurabile** — risultato di test, exit code di build, conteggio file,
   coda vuota. Non due obiettivi nella stessa condizione: due goal in sequenza.
2. **Il check dichiarato** — il comando esatto e l'esito atteso: `npm test exits 0`,
   `git status is clean`.
3. **I vincoli che non devono cambiare** — la difesa anti reward-hacking: *"no other test file
   is modified"*, "no `.skip`/`.only`", "coverage thresholds not lowered".
4. **La clausola di stop** — *"or stop after 20 turns"* (o un limite di tempo) **dentro la
   condizione stessa**. È il pattern ufficiale per limitare i run.
5. **Evidence-in-transcript** *(nostra regola derivata dal vincolo del valutatore)* — il
   valutatore Haiku non esegue tool: la condizione deve obbligare il worker a **incollare
   l'output dei check nella conversazione**, altrimenti il giudizio è cieco.
6. **≤ 4.000 caratteri.**

Checklist anti reward-hacking (sintesi delle fonti):

- [ ] I vincoli vietano esplicitamente di modificare i test/le soglie invece del codice
- [ ] Il verifier è **fresco e separato**: vede solo diff + criteri, non il ragionamento che
      ha prodotto la modifica
- [ ] I finding del reviewer sono **scopati alla correttezza**: un reviewer promptato a "trovare
      gap" ne riporterà anche quando il lavoro è solido (over-reporting documentato nelle docs)
- [ ] La rubrica deriva da un artefatto noto-buono, non da aspirazioni
- [ ] C'è un budget: clausola turni/tempo in `/goal`, `max_iterations` in CMA, Task Budget API
      (`output_config.task_budget`, min 20k token) per i loop via API

---

## 3. Quale primitiva per quale lavoro

| Primitiva | Quando usarla | Verifica intrinseca | Stop intrinseco |
|---|---|---|---|
| **`/goal`** | task finito con stato finale misurabile (feature, fix, refactor) | valutatore Haiku, transcript-only | condizione soddisfatta + clausola turni |
| **Stop hook con script** | quando il check è 100% eseguibile e deterministico | il tuo script pass/fail | cap 8 blocchi senza progresso |
| **`/loop Nm`** (fisso) | monitoraggio e manutenzione ricorrente | ❌ → mettila nel prompt | tu, o 7 giorni |
| **`/loop`** (self-paced) | attese esterne a cadenza variabile (CI, deploy, code review) | ❌ → nel prompt | Claude non rischedula quando è finito |
| **`/schedule`** (cloud) | ricorrenze oltre i 7 giorni, laptop chiuso | ❌ → nel prompt | gestione routine |
| **CMA Outcome** | run lunghi hosted con rubrica multi-criterio | grader sub-agent indipendente | `satisfied` / `max_iterations` |
| **Ralph bash loop** | fuori da Claude Code, massima semplicità, greenfield massivi | back pressure (test/compiler) + umano | operatore |

Le docs ufficiali descrivono **4 gate di verifica a escalation** — scegli il più leggero che basta:
1. **Check in-prompt** ("run the tests and show me the output")
2. **Condizione `/goal`** (valutatore modello a ogni turno)
3. **Stop hook** (script che blocca la fine turno finché non passa)
4. **Second opinion** (reviewer avversariale in subagent fresco, vede solo diff + criteri)

---

## 4. Il playbook per fase

Legenda: ✅ = pattern verificato sulle fonti primarie · 🔧 = progettato da noi applicando la
rubrica ufficiale (la ricerca non ha trovato pattern verificati per queste fasi — è uno dei
gap dichiarati). Adatta i comandi di check al repo (qui: `npm run check` = lint + typecheck +
build, `npm test`).

### 4.1 Requirements & Planning 🔧

Il loop autonomo rende poco in questa fase (serve l'umano); usa `/goal` come **gate di
completezza del documento**, non come sostituto della conversazione.

```
/goal docs/feature/<name>/spec.md exists and is complete. Definition of complete:
(1) a one-paragraph Job-to-be-Done statement, (2) at least 5 user stories each with
Given/When/Then acceptance criteria, (3) an explicit out-of-scope section,
(4) an open-questions section where every blocking question is either answered or
marked [TO CONFIRM: owner]. Check: paste the document's table of contents and the
count of stories/criteria in the conversation. Constraints: do not invent business
data — anything unknown is marked [TO CONFIRM]; do not edit files outside
docs/feature/<name>/. Or stop after 15 turns.
```

Failure mode tipico: il modello "risolve" le open questions inventando risposte → il vincolo
`[TO CONFIRM]` è il guardrail.

### 4.2 Spike / Walking skeleton 🔧

Obiettivo: il filo end-to-end più sottile che dimostra il meccanismo rischioso.

```
/goal A walking skeleton of <feature> runs end to end: `npm run dev` boots cleanly,
<the one risky path, e.g. POST /api/quote returns a PDF with non-zero bytes>, and a
smoke test in e2e/<name>-skeleton.spec.ts passes. Check: paste the smoke-test runner
output showing 1 passed. Constraints: hard-coding is allowed where the real data
source is undecided, but every hard-coded value gets a TODO(skeleton) comment;
do not touch unrelated routes or components. Or stop after 25 turns.
```

### 4.3 Scaffolding / Setup 🔧

```
/goal The project scaffold for <module> is in place: directory structure matches the
layout in docs/feature/<name>/spec.md §Structure, `npm run check` exits 0, and every
new file contains either real minimal implementation or an explicit `throw new
Error("not implemented")` — no silent empty stubs. Check: paste the `tree` of the new
directories and the check output. Constraints: no business logic in this phase; do
not modify existing modules. Or stop after 10 turns.
```

### 4.4 Implementazione TDD (red → green) 🔧

Il prompt chiede **prova del rosso e del verde** — è questo che impedisce i test tautologici.

```
/goal Story <ID> ("<title>") is implemented test-first. Definition of done:
(1) new tests exist that demonstrably FAIL before the implementation and PASS after,
(2) `npm test` exits 0 with no skipped tests, (3) `npm run check` exits 0.
Check: paste BOTH the red output (tests failing against the pre-implementation code)
and the final green output in the conversation. Constraints: never modify existing
test assertions; never add .skip or .only; never lower coverage thresholds;
implementation confined to <paths>. Or stop after 40 turns.
```

Variante Ralph (fuori da Claude Code, una story per iterazione):

```bash
while :; do cat PROMPT.md | claude -p --dangerously-skip-permissions; done
# PROMPT.md: "Read SPECS.md and PROGRESS.md. Pick the SINGLE next unimplemented story.
# Implement it test-first (red proof, then green). Run `npm run check && npm test`.
# If green: commit, mark the story done in PROGRESS.md. ONLY ONE STORY PER RUN."
```

Disciplina Ralph verificata: un task per iterazione, spec come allocazione di memoria,
**tu guardi il loop** e quando un failure domain si ripete lo risolvi permanentemente nel
prompt/spec/tooling.

### 4.5 Test hardening / mutation testing 🔧

```
/goal The mutation score for <paths> is >= 80%. Check: paste the mutation-testing
summary table (e.g. Stryker) showing the final score in the conversation.
Constraints: raise the score ONLY by adding or strengthening tests — production code
may change only to delete provably dead code (state the proof); do not exclude files
from the mutation config; do not lower the threshold. Or stop after 30 turns or 2
hours, whichever comes first.
```

### 4.6 Refactoring 🔧

Lo stato finale è strutturale + comportamento invariato — entrambi misurabili.

```
/goal <target, e.g. src/components/Configurator.tsx (1,200 lines)> is decomposed:
no file in the refactor scope exceeds 300 lines, `npm run check` exits 0, and
`npm test` passes with ZERO changes to test assertions. Check: paste `wc -l` of the
resulting files and the green test output. Constraints: behavior-preserving only —
public props/exports and rendered output must not change; one commit per extracted
unit; if a behavior change turns out to be required, STOP and report instead of
proceeding. Or stop after 30 turns.
```

### 4.7 Code review & PR babysitting ✅ (i pattern verificati di Cherny)

Il loop ricorrente — questa è pratica documentata, non nostra invenzione:

```
/loop 5m /babysit-prs
# dove /babysit-prs è una TUA skill ("skills + loops"):
# "List my open PRs with `gh pr list`. For each: address new review comments with
#  minimal commits, rebase onto main if behind, re-request review when CI is green.
#  If there is nothing to do, do nothing."
```

Il gate avversariale prima del merge (gate 4 — second opinion):

```
/goal The diff on branch <branch> has passed adversarial review. Process: spawn a
fresh reviewer subagent that sees ONLY `git diff main...HEAD` and the criteria below
— not the reasoning that produced the change. Criteria: correctness bugs, broken
contracts, security issues. For each finding: fix it, or refute it with evidence
pasted in the conversation. Done when a second fresh reviewer pass reports zero
correctness findings. Constraints: findings scoped to correctness, not style; no
history rewriting. Or stop after 20 turns.
```

### 4.8 CI / Deploy 🔧

Attesa esterna a cadenza variabile → `/loop` self-paced (Claude sceglie il ritmo e si
auto-termina non rischedulando):

```
/loop Watch the GitHub Actions run for the latest commit on <branch> using
`gh run list` / `gh run view --log-failed`. If a job failed: read the logs, fix the
root cause, push, and keep watching the new run. When the pipeline is green AND the
preview deploy responds 200, paste the run URL and the preview URL, then stop the
loop. Never force-push; never edit the workflow file to skip failing steps.
```

Il vincolo finale è l'anti-reward-hack specifico di questa fase: il modo più rapido per
"far passare la CI" è manomettere la CI.

### 4.9 Maintenance / Bug-fixing 🔧

```
/goal Bug <ID> ("<symptom>") is fixed with a regression test. Definition of done:
(1) the root cause is stated in one paragraph citing file:line, (2) a regression
test exists that FAILS on the pre-fix code and PASSES post-fix, (3) `npm run check`
and `npm test` exit 0. Check: paste both test outputs (red via `git stash` on the
fix, then green). Constraints: minimal diff — no drive-by refactors; fix the cause,
not the symptom (no swallowing errors); do not touch unrelated tests.
Or stop after 25 turns.
```

Triage notturno ricorrente (oltre 7 giorni → routine cloud):

```
/schedule daily 07:00 — Triage new GitHub issues: reproduce each new bug report in a
worktree; if reproducible, write the failing regression test and open a draft PR
containing ONLY the test plus a root-cause analysis comment. Do not attempt the fix.
Cap: 3 issues per run.
```

(Il cap per run è il budget ceiling applicato a un loop ricorrente.)

### 4.10 Documentazione 🔧

```
/goal Documentation for <module> matches the code. Definition of done: every exported
symbol in <paths> has a doc comment, and docs/<HANDOFF or README>.md §<section> is
updated to describe current behavior. Check: paste the output of the doc-coverage
command (or a grep showing zero undocumented exports). Constraints: document observed
behavior only — verify each claim against the code before writing it; do not change
any source code. Or stop after 10 turns.
```

---

## 5. L'outer loop: memoria tra sessioni

I loop sopra sono *inner loop* (dentro una sessione). L'outer loop è la memoria che attraversa
le sessioni — ed è dove Fable 5 si distingue (Continual Learning Bench): la progressione
completa è **fail → investigate → verify → distill → consult**. I modelli più deboli si fermano
al primo stadio (lista di note di fallimento mai consultate).

Blocco da appendere ai prompt dei loop lunghi:

```
MEMORY DISCIPLINE — at the end of every iteration, update <memory file> following
this progression: when something failed, document it (FAIL); before moving on,
explain why it failed (INVESTIGATE); turn the diagnosis into a fact you actually
checked (VERIFY); rewrite verified facts as general rules (DISTILL). At the START of
every iteration, read the rules first instead of re-deriving them (CONSULT).
```

È la stessa cosa che Huntley fa manualmente ("resolve the problem so it never happens again"),
resa istruzione per il modello.

---

## 6. I tre hard stop, mappati sulle meccaniche reali

La letteratura 2026 converge su tre guardrail; ecco come si implementano concretamente:

| Hard stop | In `/goal` | In `/loop`/`/schedule` | Via API |
|---|---|---|---|
| **Max iterazioni** | clausola *"or stop after N turns"* nella condizione | cap espliciti nel prompt ("3 issues per run") + scadenza 7 giorni | `max_iterations` (CMA Outcomes, default 3, max 20) |
| **No-progress detection** | il motivo del "no" del valutatore guida il turno dopo; Stop hook: override dopo 8 blocchi senza progresso | istruzione *"if two consecutive iterations produce no diff, stop and report"*; self-paced può non rischedulare | grader `needs_revision` con gap per-criterio |
| **Budget ceiling** | clausola di tempo ("or 2 hours") | intervalli larghi; cap 50 task/sessione | Task Budget (`output_config.task_budget`, min 20k token — il modello vede il countdown) |

Promemoria di umiltà: i guardrail **limitano, non eliminano** (issue #55754: quota di sessione
bruciata in ~50 minuti da uno Stop-hook loop). Per i loop nuovi: prima supervisionato, poi
walk-away. Come dicono le docs: il check eseguibile è *"the difference between a session you
watch and one you walk away from"*.

---

## 7. Adattamento a questo repo

- Il check standard qui è **`npm run check`** (lint + typecheck + build) + `npm test` dove
  presente: è il "runnable pass/fail" da incollare nel transcript in ogni goal condition.
- Composizione **skills + loops** (raccomandazione verificata di Cherny): le skill nWave del
  repo sono già workflow impacchettati — candidati naturali: `/loop 30m /nw-continue` (riprende
  la wave corrente), un `/babysit-prs` custom per la 4.7, `/schedule` per il triage notturno.
  Crea prima la skill, poi mettila in loop: mai loop su prompt ad-hoc lunghi.
- Per i run multi-agente vale la regola del CLAUDE.md: ogni teammate nel proprio worktree,
  merge orchestrato alla fine.
- **Modello del valutatore `/goal`:** in questo repo è impostato a **Opus 4.8**
  (`claude-opus-4-8`), non il default Haiku — config (campo `model` su Stop hook a prompt) e
  tradeoff costo/latenza in `SUPERVISOR-LOOP-ORCHESTRATION.md` §10. Resta transcript-only: la
  regola evidence-in-transcript (§2.5) non si rilassa con un giudice più forte.

---

## 8. Fonti

**Primarie (claim verificati verbatim, 2026-06-10):**
- Boris Cherny — 5 tips: x.com/bcherny/status/2063792263067754658 · threads.com/@boris_cherny/post/DZTmR4omqZ3
- Boris Cherny — /loop & /schedule, /babysit, skills+loops: threads.com/@boris_cherny/post/DWfjpUNlKzx · x.com/bcherny/status/2038454341884154269
- Docs ufficiali: code.claude.com/docs/en/goal · /scheduled-tasks · /best-practices · /hooks-guide
- Geoffrey Huntley: ghuntley.com/ralph (lug 2025) · ghuntley.com/loop ("Everything is a Ralph Loop", gen 2026) · plugin ralph-wiggum in github.com/anthropics/claude-code
- Anthropic engineering: anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Lance Martin — "Designing loops with Fable 5" (Parameter Golf, memoria): x.com/RLanceMartin/status/2064397389189071163 (testo integrale in `goal&loop.md` alla radice del repo)
- Doc API: CMA Outcomes (`user.define_outcome`, rubriche, grader), Task Budgets

**Non verificate / smentite (non citare come fatti):**
- "Three-stage definition of loops" di Cherny (nessuna fonte primaria trovata)
- Dettagli di Gas Town (Mayor/patrol agents) — zero claim sopravvissuti alla verifica
- "Centinaia/migliaia di sub-agenti" nel tip dynamic-workflows (smentito 1-2)
- fix_plan.md come stopping condition di Ralph (smentito 1-2)
