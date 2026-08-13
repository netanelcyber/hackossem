#!/usr/bin/env python3
"""
build_subtitled_video.py — reassemble extracted video frames into an MP4 with
an English text-to-speech voiceover and matching burned-in subtitles.

Made for the RecruitX / TryHackMe "Guided Pentest Web" walkthrough recap in this
repo. The narration is generated offline with espeak-ng (robotic but no network),
and the frame timing, subtitle timing, and audio are all synced per segment.

Requirements: ffmpeg, ffprobe, espeak-ng
    apt-get install -y ffmpeg espeak-ng

Usage:
    python3 build_subtitled_video.py <frames_dir> [output.mp4]

    <frames_dir> must contain frame_000001.jpg ... frame_NNNNNN.jpg
    Adjust SEGMENTS below so the frame ranges match your own extraction.
"""
import os, sys, subprocess

FRAMES = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else "frames"
OUT    = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else "walkthrough.mp4"
WORK   = os.path.dirname(OUT) or "."
PAD    = 0.5  # seconds of silence appended after each spoken segment

# (frame_start, frame_end, narration_text, on_screen_caption)
# Frame ranges are contiguous and must cover every frame you extracted.
SEGMENTS = [
    (1, 40,
     "TryHackMe, Guided Pentest Web. The target is RecruitX version two point four, "
     "a recruitment web app. An Nmap scan finds four ports: twenty-two S S H, "
     "eighty H T T P on Apache, three three zero six MySQL, and eighty eighty.",
     "TryHackMe: Guided Pentest Web — target RecruitX v2.4.\n"
     "Nmap: 22/SSH, 80/HTTP (Apache 2.4.58), 3306/MySQL, 8080."),
    (41, 90,
     "We register an account, log in to RecruitX, "
     "and inspect the H T T P response headers of the application.",
     "Register + log in to RecruitX, then inspect the HTTP response headers."),
    (91, 150,
     "Using Gobuster we brute force directories and discover admin, "
     "a p i, profile dot php, reset dot php, uploads, and more.",
     "Gobuster directory brute force →\n/admin, /api, /profile.php, /reset.php, /uploads ..."),
    (151, 210,
     "The a p i endpoint leaks internal routes, an information disclosure issue. "
     "We confirm Apache two point four point five eight and a MySQL backend.",
     "The /api endpoint leaks internal routes (info disclosure).\nApache 2.4.58, MySQL backend."),
    (211, 260,
     "Now the key bug: an I-DOR. Opening profile dot php with i-d equals one "
     "reveals the administrator, Sarah Mitchell.",
     "IDOR: profile.php?id=1 reveals the admin — Sarah Mitchell."),
    (261, 330,
     "By changing the i-d parameter we enumerate every user, exposing names, roles, "
     "and the admin email, s dot mitchell at recruitx dot thm.",
     "Iterate the id → enumerate every user.\nAdmin email: s.mitchell@recruitx.thm"),
    (331, 390,
     "Our own profile is i-d six. The app trusts the numeric i-d with no access control, "
     "so any value returns another user's data.",
     "Your profile is id=6. No access control on the numeric id →\nany value returns another user's data."),
    (391, 430,
     "The password reset is weak: a short numeric token that can be brute forced. "
     "We reset Sarah Mitchell's password and log in as the administrator.",
     "Weak password reset: short numeric token → brute force.\nReset the admin's password and log in."),
    (431, 470,
     "Inside the admin panel is a file upload. The type filter is client side only, "
     "so we remove the accept attribute to bypass it.",
     "Admin panel upload — filter is client-side only.\nRemove the 'accept' attribute to bypass."),
    (471, 520,
     "The server blocks dot t x t, but a dot phtml file slips through. "
     "The handler is upload dot php and files land in uploads, documents.",
     "Server blocks .txt but allows .phtml.\nHandler: upload.php → files in /uploads/documents/"),
    (521, 579,
     "Visiting the uploaded phtml file, the server runs the P H P and prints "
     "P H P is executing. Remote code execution is confirmed. Next step: a reverse shell.",
     "test.phtml runs → \"PHP is executing\" = RCE confirmed.\nNext: reverse shell."),
]

def dur(path):
    return float(subprocess.check_output(
        ["ffprobe","-v","error","-show_entries","format=duration",
         "-of","default=nk=1:nw=1", path]).decode().strip())

def srt_ts(t):
    h=int(t//3600); m=int((t%3600)//60); s=int(t%60); ms=int(round((t-int(t))*1000))
    if ms==1000: s+=1; ms=0
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"

def run(*a):
    subprocess.check_call(list(a), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

os.chdir(WORK)
seg_durs=[]
for i,(fs,fe,text,cap) in enumerate(SEGMENTS):
    raw=f"seg_{i:02d}_raw.wav"; pad=f"seg_{i:02d}.wav"
    run("espeak-ng","-v","en-us","-s","150","-p","45","-w",raw,text)
    run("ffmpeg","-y","-i",raw,"-af",f"apad=pad_dur={PAD}","-ar","22050","-ac","1",pad)
    seg_durs.append(dur(pad))

# subtitles
srt=[]; t=0.0
for i,(fs,fe,text,cap) in enumerate(SEGMENTS):
    srt.append(f"{i+1}\n{srt_ts(t)} --> {srt_ts(t+seg_durs[i]-0.05)}\n{cap}\n")
    t+=seg_durs[i]
open("subs.srt","w").write("\n".join(srt))

# audio concat list
with open("concat_audio.txt","w") as f:
    for i in range(len(SEGMENTS)):
        f.write(f"file '{os.path.join(WORK,f'seg_{i:02d}.wav')}'\n")

# video concat list: each frame gets seg_dur / n_frames
with open("concat_video.txt","w") as f:
    f.write("ffconcat version 1.0\n"); last=None
    for i,(fs,fe,text,cap) in enumerate(SEGMENTS):
        per=seg_durs[i]/(fe-fs+1)
        for fn in range(fs,fe+1):
            last=os.path.join(FRAMES,f"frame_{fn:06d}.jpg")
            f.write(f"file '{last}'\nduration {per:.4f}\n")
    f.write(f"file '{last}'\n")

run("ffmpeg","-y","-f","concat","-safe","0","-i","concat_audio.txt",
    "-ar","22050","-ac","1","narration.wav")

style=("FontName=DejaVu Sans,FontSize=13,PrimaryColour=&H00FFFFFF&,"
       "OutlineColour=&H00000000&,BorderStyle=1,Outline=2,Shadow=1,"
       "Alignment=2,MarginV=20")
run("ffmpeg","-y","-f","concat","-safe","0","-i","concat_video.txt","-i","narration.wav",
    "-vf",f"subtitles=subs.srt:force_style='{style}'",
    "-c:v","libx264","-preset","veryfast","-crf","26","-pix_fmt","yuv420p","-r","25",
    "-c:a","aac","-b:a","128k","-shortest",OUT)
print("wrote", OUT, "and subs.srt")
