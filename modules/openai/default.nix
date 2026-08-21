{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.openai;
in
{
  options.openai = {
    enable = lib.mkEnableOption "Configure OpenAI CLI and voice tools";

    apiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to file containing OpenAI API key";
      example = "/run/secrets/openai-api-key";
    };

    # voiceCommands = {
    #   enable = lib.mkEnableOption "Voice-to-command terminal tools";

    #   confirmBeforeExec = lib.mkOption {
    #     type = lib.types.bool;
    #     default = true;
    #     description = "Confirm transcribed commands before execution";
    #   };

    #   model = lib.mkOption {
    #     type = lib.types.str;
    #     default = "whisper-1";
    #     description = "OpenAI model to use for transcription";
    #   };
    # };

    # voiceToText = {
    #   enable = lib.mkEnableOption "Voice-to-text input for any application";

    #   hotkey = lib.mkOption {
    #     type = lib.types.nullOr lib.types.str;
    #     default = null;
    #     description = "Global hotkey to start voice transcription";
    #     example = "cmd+shift+space";
    #   };
    # };

    # aiChat = {
    #   enable = lib.mkEnableOption "ai-chat tool";
    # };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      openai
      # sox # for audio recording
      # ffmpeg_6-headless # for audio processing
    ];

    # Set OpenAI API key if provided
    home.sessionVariables = lib.mkIf (cfg.apiKeyFile != null) {
      OPENAI_API_KEY = "$(cat ${cfg.apiKeyFile})";
    };

    # home.file = lib.mkMerge [
    #   # Voice command script
    #   (lib.mkIf cfg.voiceCommands.enable {
    #     "bin/voice-cmd" = {
    #       executable = true;
    #       text = ''
    #         #!/usr/bin/env bash

    #         VERSION="0.1"

    #         set -euo pipefail

    #         parser_definition() {
    #           setup   REST help:usage -- "Usage: voice-cmd [options]... [arguments]..." \'\'
    #           msg -- 'Options:'
    #           flag    DEBUG    -d --debug                -- "enables debug level log messages"
    #           flag    SILENT   -s --silent               -- "silences all output"
    #           param   DURATION -t --duration on:5        -- "sets the amount of time to listen for user input"
    #           disp    :usage      --help
    #           disp    VERSION     --version
    #         }

    #         eval "$(getoptions parser_definition) exit 1"

    #         debug() { [[ ''${DEBUG-} ]] && printf '%s\n' "$*" >&2; }
    #         error() { [[ ''${SILENT-} ]] || printf '%s\n' "$*" >&2; }

    #         error "function not done"
    #         exit 1

    #         # Check if OpenAI API key is set
    #         if [[ -z "''${OPENAI_API_KEY:-}" ]]; then
    #           error "Error: OPENAI_API_KEY not set"
    #           exit 1
    #         fi

    #         # Record audio
    #         TEMP_AUDIO="/tmp/voice-cmd-$(date +%s).wav"

    #         debug "🎤 Recording for $DURATION seconds... (Press Ctrl+C to stop early)"

    #         # Record audio using sox
    #         timeout "$DURATION" sox -d "$TEMP_AUDIO" rate 16k channels 1 2>/dev/null || true

    #         if [[ ! -f "$TEMP_AUDIO" ]]; then
    #           error "❌ No audio recorded"
    #           exit 1
    #         fi

    #         debug "🔄 Transcribing..."

    #         # Transcribe using OpenAI
    #         TRANSCRIPTION=$(openai api audio.transcriptions.create \
    #           --model "${cfg.voiceCommands.model}" \
    #           --file "$TEMP_AUDIO" \
    #           --response-format text 2>/dev/null || echo "")

    #         # Clean up temp file
    #         rm -f "$TEMP_AUDIO"

    #         if [[ -z "$TRANSCRIPTION" ]]; then
    #           error "❌ Failed to transcribe audio"
    #           exit 1
    #         fi

    #         echo "📝 Transcribed: $TRANSCRIPTION"

    #         ${lib.optionalString cfg.voiceCommands.confirmBeforeExec ''
    #           # Ask for confirmation
    #           echo -n "🤔 Execute this command? [y/N]: "
    #           read -r CONFIRM

    #           if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    #             error "❌ Command cancelled"
    #             exit 0
    #           fi
    #         ''}

    #         debug "🚀 Executing: $TRANSCRIPTION"
    #         eval "$TRANSCRIPTION"
    #       '';
    #     };
    #   })

    #   # Voice-to-text script
    #   (lib.mkIf cfg.voiceToText.enable {
    #     "bin/voice-to-text" = {
    #       executable = true;
    #       text = ''
    #         #!/usr/bin/env bash

    #         VERSION="0.1"

    #         set -euo pipefail

    #         parser_definition() {
    #           setup   REST help:usage -- "Usage: voice-cmd [options]... [arguments]..." \'\'
    #           msg -- 'Options:'
    #           flag    DEBUG    -d --debug                -- "enables debug level log messages"
    #           flag    SILENT   -s --silent               -- "silences all output"
    #           param   DURATION -t --duration on:5        -- "sets the amount of time to listen for user input"
    #           disp    :usage      --help
    #           disp    VERSION     --version
    #         }

    #         eval "$(getoptions parser_definition) exit 1"

    #         debug() { [[ ''${DEBUG-} ]] && printf '%s\n' "$*" >&2; }
    #         error() { [[ ''${SILENT-} ]] || printf '%s\n' "$*" >&2; }

    #         error "function not done"
    #         exit 1

    #         # Check if OpenAI API key is set
    #         if [[ -z "''${OPENAI_API_KEY:-}" ]]; then
    #           error "Error: OPENAI_API_KEY not set"
    #           exit 1
    #         fi

    #         # Record audio
    #         TEMP_AUDIO="/tmp/voice-to-text-$(date +%s).wav"

    #         debug "🎤 Recording for $DURATION seconds..."

    #         # Record audio using sox
    #         timeout "$DURATION" sox -d "$TEMP_AUDIO" rate 16k channels 1 2>/dev/null || true

    #         if [[ ! -f "$TEMP_AUDIO" ]]; then
    #           error "❌ No audio recorded"
    #           exit 1
    #         fi

    #         debug "🔄 Transcribing..."

    #         # Transcribe using OpenAI
    #         TRANSCRIPTION=$(openai api audio.transcriptions.create \
    #           --model "${cfg.voiceCommands.model}" \
    #           --file "$TEMP_AUDIO" \
    #           --response-format text 2>/dev/null || echo "")

    #         # Clean up temp file
    #         rm -f "$TEMP_AUDIO"

    #         if [[ -z "$TRANSCRIPTION" ]]; then
    #           error "❌ Failed to transcribe audio"
    #           exit 1
    #         fi

    #         debug "📝 Transcribed: $TRANSCRIPTION"

    #         # Copy to clipboard and optionally type it
    #         echo -n "$TRANSCRIPTION" | pbcopy
    #         debug "📋 Copied to clipboard!"

    #         # Ask if user wants to type it automatically
    #         echo -n "⌨️  Type this text automatically? [y/N]: "
    #         read -r AUTO_TYPE

    #         if [[ "$AUTO_TYPE" == "y" || "$AUTO_TYPE" == "Y" ]]; then
    #           # Give user time to switch windows
    #           debug "⏱️  Switching to target window in 3 seconds..."
    #           sleep 3

    #           # Type the text (using osascript on macOS)
    #           osascript -e "tell application \"System Events\" to keystroke \"$TRANSCRIPTION\""
    #         fi
    #       '';
    #     };
    #   })

    #   # Quick OpenAI chat script
    #   (lib.mkIf cfg.aiChat.enable {
    #     "bin/ai-chat" = {
    #       executable = true;
    #       text = ''
    #         #!/usr/bin/env bash

    #         VERSION="0.1"

    #         set -euo pipefail

    #         parser_definition() {
    #           setup   REST help:usage -- "Usage: ai [options] chat-prompt"
    #           msg -- 'Options:'
    #           flag    DEBUG      -d --debug                -- "enables debug level log messages"
    #           flag    SILENT     -s --silent               -- "silences all output"
    #           param   MODEL      -m --model on:"gpt-4"     -- "sets model that the ai uses"
    #           flag    NO_STREAM  --no-stream               -- "outputs complete responses from the model, does not stream results"
    #           disp    :usage     --help
    #           disp    VERSION    --version
    #         }

    #         eval "$(getoptions parser_definition) exit 1"

    #         MODEL=''${MODEL:-"gpt-4"}

    #         debug() { [[ ''${SILENT-} ]] || ([[ ''${DEBUG-} ]] && printf '%s\n' "$*" >&2;) }
    #         error() { [[ ''${SILENT-} ]] || printf '%s\n' "$*" >&2; }

    #         debug "Creating openai chat completion..."
    #         debug " * model: $MODEL"
    #         debug " * prompt: $@"

    #         echo "$@"

    #         openai api chat.completions.create \
    #           --model "$MODEL" \
    #           --max-tokens 1000 \
    #           --stream \
    #           --message system "You are a helpful assistant running in the command line interface." \
    #           --message user "$@"
    #       '';
    #     };
    #   })
    # ];

    # # Shell aliases
    # programs.zsh.shellAliases = {
    #   ai = "ai-chat";
    # }
    # // lib.mkIf cfg.voiceCommands.enable { vc = "voice-cmd"; }
    # // lib.mkIf cfg.voiceToText.enable { vt = "voice-to-text"; };
  };
}
