# FileAtlas AI Help

## Purpose

FileAtlas shows optional AI help only on the first-start screen, while no saved
scan locations, recent locations, or indexed entries exist. As soon as the
person adds a folder or FileAtlas has content, the standard three-column view
is shown instead.

## Privacy

The help prompt is fixed in the app source. It includes only the app name,
general first-start instructions, and the public manual URL for the selected
app language. It never includes local paths, catalog contents, file metadata,
health data, license data, credentials, passwords, tokens, or any other user
data.

Selecting ChatGPT, Gemini, or Claude copies the prompt to the clipboard first
and then opens the selected website. FileAtlas does not open a service on its
own, paste the prompt, or submit anything. The person decides whether to paste
the text with Cmd+V and send it.

## Public Manuals

- German: <https://github.com/Schrotty74/FileAtlas/blob/main/output/pdf/FileAtlas-Handbuch.pdf>
- English: <https://github.com/Schrotty74/FileAtlas/blob/main/output/pdf/FileAtlas-Manual-EN.pdf>

## Local Service Logos

The first-start screen packages the following unmodified, local files solely
to identify the optional services. No image is downloaded at runtime.

- `FileAtlas/Resources/AI/fileatlas-chatgpt-logo.jpg`: official ChatGPT app
  icon distributed through Apple's App Store.
- `FileAtlas/Resources/AI/fileatlas-gemini-logo.svg`: official Gemini symbol
  distributed by Google.
- `FileAtlas/Resources/AI/fileatlas-claude-logo.png`: official Claude app
  symbol distributed by Anthropic.

ChatGPT and OpenAI are trademarks of OpenAI. Gemini and Google are trademarks
of Google. Claude and Anthropic are trademarks of Anthropic. Their display
does not imply a partnership or recommendation.
