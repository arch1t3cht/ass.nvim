from datetime import timedelta
import re
import subprocess
import tempfile
import vim

D_LAYER = 0
D_START = 1
D_END = 2
D_STYLE = 3
D_NAME = 4
D_MARGINL = 5
D_MARGINR = 6
D_MARGINV = 7
D_EFFECT = 8
D_TEXT = 9

split_re = re.compile("[\\.:]")

def parse_time(t):
    assert(t[i] == ":" for i in [1, 4])
    assert(t[7] in ".:")
    assert(len(t) == 10)
    fields = [int(f) for f in split_re.split(t)]
    assert(len(fields) == 4)

    return timedelta(
            hours=fields[0],
            minutes=fields[1],
            seconds=fields[2],
            microseconds=10000 * fields[3])


def format_td(td):
    return "{}:{:02}:{:02}.{:02}".format(
            td.seconds // 3600,
            (td.seconds % 3600) // 60,
            td.seconds % 60,
            round(td.microseconds / 10000))


def parse_dialogue(line):
    if not line.startswith("Dialogue:") or line.startswith("Comment:"):
        return []
    lines = line.split(",", D_TEXT)
    if len(lines) != D_TEXT + 1:
        return []
    return lines


def assemble_dialogue(parts):
    return ",".join(parts)


def replace_line(l1, l2):
    p1 = parse_dialogue(l1)
    p2 = parse_dialogue(l2)
    if not p1 or not p2:
        return None
    # TODO keep tags?
    p1[D_TEXT] = p2[D_TEXT]
    return assemble_dialogue(p1)


def append_line(l1, l2):
    p1 = parse_dialogue(l1)
    if not p1:
        return None
    p1[D_TEXT] = p1[D_TEXT].strip() + " " + parse_dialogue(l2)[D_TEXT].strip()
    return assemble_dialogue(p1)


def join_lines(lines):
    pl = [parse_dialogue(l) for l in lines if l]
    if not pl:
        return None

    line = pl[0]
    line[D_TEXT] = " ".join(l[D_TEXT].strip() for l in pl)
    line[D_END] = pl[-1][D_END]

    return assemble_dialogue(line)


def escape_cmd(s):
    return s.replace("'", "'\"'\"'")


def show(line, sname):
    vidlines = [l for l in vim.current.buffer if l.startswith("Video File: ")]
    if not vidlines:
        print("No video file listed!")
        return

    vidfile = vidlines[0].removeprefix("Video File: ")

    l = parse_dialogue(line)
    if not l:
        return

    t1 = parse_time(l[D_START])
    t2 = parse_time(l[D_END])

    t = format_td((t1 + t2) / 2)

    subprocess.Popen(["bash", "-c",
        "f=$(mktemp --suffix .bmp) && ffmpeg -ss {} -copyts -i '{}' -vf subtitles='{}' -vframes 1 $f -y && feh $f && rm $f"
        .format(t, vidfile, sname)])

