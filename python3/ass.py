from datetime import timedelta
import re
import subprocess
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

time_re = re.compile("^([0-9]):([0-9]{2}):([0-9]{2})[.:]([0-9]{2})$")

START_LENGTH = 50

mpv_args_video = []
mpv_args_audio = []

def parse_time(t):
    m = time_re.match(t)
    if not m:
        return None

    fields = [int(i) for i in m.groups()]

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


def split_line(l1, l2, x):
    p1 = parse_dialogue(l1)
    p2 = parse_dialogue(l2)
    if not p1 or not p2:
        return None

    # encode and decode to make sure special characters are handled correctly
    # vim's cursor position is in terms of bytes, not characters
    linex = x - len(assemble_dialogue(p1[:D_TEXT] + [""]).encode())
    t = p1[D_TEXT].encode()

    # If we're in the middle of \N, also split this properly
    if linex >= 1 and t[linex] == ord("N") and t[linex - 1] == ord("\\"):
        linex += 1

    t1, t2 = t[:linex].decode().strip(), t[linex:].decode().strip()
    # strip trailing and leading newlines
    while t1.endswith("\\N"):
        t1 = t1[:-2].strip()
    while t2.startswith("\\N"):
        t2 = t2[2:].strip()

    p1[D_TEXT] = t1
    p2[D_TEXT] = t2

    return (assemble_dialogue(p1), assemble_dialogue(p2))


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


def get_av(name):
    vidlines = [l for l in vim.current.buffer if l.startswith(f"{name} File: ")]
    if not vidlines:
        return None
    return vidlines[0].removeprefix(f"{name} File: ")


def get_play_cmd(line, opt, background):
    afile = get_av("Audio")
    if not afile:
        print("No audio file")
        return

    l = parse_dialogue(line)
    if not l:
        print("Invalid line")
        return None

    t1 = parse_time(l[D_START])
    t2 = parse_time(l[D_END])

    if not (t1 and t2):
        print("Invalid line")
        return None

    start = None
    end = None

    if opt == "line":
        start, end = t1, t2
    elif opt == "all":
        start, end = t1, None
    elif opt == "begin":
        start, end = t1, t1 + timedelta(microseconds=10000 * START_LENGTH)
    elif opt == "end":
        start, end = t2 - timedelta(microseconds=10000 * START_LENGTH), t2
    elif opt == "before":
        start, end = t1 - timedelta(microseconds=10000 * START_LENGTH), t1
    elif opt == "after":
        start, end = t2, t2 + timedelta(microseconds=10000 * START_LENGTH)

    cmd = ["mpv",  afile] + mpv_args_audio

    if start:
        cmd.append("--start=" + format_td(start))
    if end:
        cmd.append("--end=" + format_td(end))

    if background:
        subprocess.Popen(cmd)
    else:
        cmd[1] = "'{}'".format(escape_cmd(cmd[1]))
        return " ".join(cmd)


def show_line(line):
    vidfile = get_av("Video")
    if not vidfile:
        print("No video file")
        return

    cmd = ["mpv", vidfile, "--sub-file=-"] + mpv_args_video
    buffer = "\r\n".join(vim.current.buffer)

    l = parse_dialogue(line)
    if l:
        t = format_td(parse_time(l[D_START]))
        if t:
            cmd.append(f"--start={t}")

    p = subprocess.Popen(cmd, stdin=subprocess.PIPE)
    p.communicate(input=buffer.encode())

