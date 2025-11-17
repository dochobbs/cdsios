## CDSMDH (iOS)

SwiftUI implementation of the pediatric Clinical CLI using GPT‑5.1 as the reasoning engine.

### Structure

- `CDSMDH.xcodeproj` – iOS 17 SwiftUI project.
- `CDSMDH/` – Source files, assets, prompts, and Info.plist.
- `CDSMDH/Resources/Prompts` – JSON prompt exports generated via `python scripts/export_prompts.py`.

### Getting Started

1. Run `python scripts/export_prompts.py` at the repo root whenever prompts change.
2. Open `ios/CDSMDH/CDSMDH.xcodeproj` in Xcode 15+.
3. Provide an OpenAI key in-app using the Settings gear (stored in the Keychain).
4. Run on iOS 17 simulator or device.

### Notable Files

| File | Purpose |
| --- | --- |
| `CDSMDHApp.swift` | Entry point with tab navigation + Settings controls |
| `GPTService.swift` | GPT‑5.1 streaming client using `/v1/chat/completions` |
| `SecureSettings.swift` | Keychain-backed API key + model management |
| `StreamingCommandViewModel.swift` | Shared streaming/state machine for every command |
| `DrugLookupViewModel.swift` | Recreates CLI drug workflow with weight parsing |
| `CDSViewModel.swift` | Clinical decision support reasoning + red-flag framing |
| `CDSView.swift` | SwiftUI form for CDS intakes (presentation, concerns, format) |
| `ChatDesign.swift` | ChatGPT-style glassmorphism components + gradients |
| `PromptTemplate.swift` | Loads JSON prompts into memory for reuse |

### Next Steps

- Add DDx, Notes, and Parse tabs by subclassing `StreamingCommandViewModel`.
- Expand UI with tabs for CDS, notes, and document parsing.
- Wire up attachment support for images/PDF once GPT endpoints accept files.

### Design Language

- Inspired by the ChatGPT mobile app: layered gradients, glass cards, pill chips, and streaming response panels.
- Uses `GlassCard`, `PrimaryActionButtonStyle`, and `StreamingOutputSection` (see `ChatDesign.swift`) to keep a consistent look across commands.
- Background gradient + blurred materials require iOS 17+; previews target iPhone 15/16 to enable the “iOS 26” design stack.

### Adding Another Command

1. Ensure a prompt JSON exists via `python scripts/export_prompts.py` (command key becomes the filename).
2. Subclass `StreamingCommandViewModel` with any intake fields you need and build the `userMessage`.
3. Create a SwiftUI view that binds to the new view model and surfaces `error`, `isStreaming`, and `output`.
4. Register the tab or screen in `CDSMDHApp` so it shows up beside Drug Lookup and CDS.
