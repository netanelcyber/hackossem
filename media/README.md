# media/ — Subtitled walkthrough video

## `RecruitX-walkthrough.mp4`

A 2:04 recap of the **TryHackMe "Guided Pentest Web"** room
([tryhackme.com/room/guidedpentestweb](https://tryhackme.com/room/guidedpentestweb)),
targeting the **RecruitX v2.4** web app. It was rebuilt from 579 extracted video
frames, with an **English text-to-speech voiceover** and matching **burned-in
English subtitles**, synced step by step.

- `RecruitX-walkthrough.en.srt` — the English subtitle track (soft subs).
- `RecruitX-walkthrough.he.mp4` — **Hebrew** version: Hebrew TTS voiceover
  (`espeak-ng -v he`) + burned-in Hebrew (RTL) subtitles.
- `RecruitX-walkthrough.he.srt` — the Hebrew subtitle track (soft subs).
- `build_subtitled_video.py` — the script that regenerates the video from frames
  (needs `ffmpeg` + `espeak-ng`; see the header for usage). For the Hebrew build,
  swap the caption/narration text, use `espeak-ng -v he`, and a Hebrew-capable
  font (e.g. `FontName=DejaVu Sans`).

> [!NOTE]
> The voiceover is generated **offline with espeak-ng** (robotic, no network) from
> a written description of each step — it is not the original audio. Near the end
> the source frames loop back to the intro, so the last caption's on-screen image
> doesn't match; the narration/caption order still follows the walkthrough.

## The attack chain (what the video covers)

A classic guided web-app pentest against RecruitX v2.4 (Apache 2.4.58 / Ubuntu):

1. **Recon** — Nmap (22/SSH, 80/HTTP, 3306/MySQL, 8080), HTTP headers, register +
   log in, then Gobuster to find `/admin`, `/api`, `/profile.php`, `/reset.php`,
   `/uploads`, and more.
2. **IDOR** — `profile.php?id=1` reveals the admin **Sarah Mitchell**; iterating
   the `id` enumerates every user (incl. `s.mitchell@recruitx.thm`).
3. **Weak password reset** — a short numeric, brute-forceable reset token lets you
   take over the admin account.
4. **Admin panel** — an "Upload Company Documents" feature with a **client-side
   only** file-type filter.
5. **File upload → RCE** — bypass the filter, upload a `.phtml` via `upload.php`
   (stored in `/uploads/documents/`); visiting it runs PHP → **RCE confirmed**,
   with a reverse shell as the next step.

> [!IMPORTANT]
> Educational content for the authorized TryHackMe lab only.
