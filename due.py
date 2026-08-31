#!/usr/bin/env python3
"""Кто из сборщиков сейчас должен работать.

🔴 Заведено 01.09.2026 по решению Дениса: расписание идёт не «в такой-то час», а
«прошло столько-то часов с прошлого прогона».

Почему так. Крон GitHub — обещание, а не гарантия: за 29 и 30 августа из восьми
назначенных прогонов состоялось семь, все с опозданием от сорока минут до шести часов,
а у рассылки крон «каждые десять минут» душился до одного прогона в сутки. Жёсткие часы
в такой среде означают, что пропущенный час просто теряется.

Здесь наоборот: попытка приходит каждый час, а решает не расписание, а время с прошлого
состоявшегося прогона. Пропущенная попытка ничего не ломает — следующая увидит, что
пора, и отработает. Файл runs.json лежит открытым текстом: в нём только отметки времени.

Печатает в GITHUB_OUTPUT строку which=main | which=cis | which=none.
"""
import json, os, sys
from datetime import datetime, timezone

HERE = os.path.dirname(os.path.abspath(__file__))
STATE = os.path.join(HERE, "runs.json")

# Через сколько часов гипотеза снова становится «пора». Согласовано с потолком трат
# в people_config.RUNS_PER_DAY: основная 6 заходов в сутки, СНГ 4.
EVERY_H = {"main": float(os.environ.get("BS_MAIN_EVERY_H", "2.5")),
           "cis": float(os.environ.get("BS_CIS_EVERY_H", "4.0"))}

# Квота Google сбрасывается в полночь по тихоокеанскому, летом это 07:00 UTC.
# Заход раньше застаёт ключи выжатыми со вчера и собирает ноль.
QUIET_BEFORE_UTC = int(os.environ.get("BS_QUIET_BEFORE_UTC", "7"))


def main():
    now = datetime.now(timezone.utc)
    out = []
    if now.hour < QUIET_BEFORE_UTC:
        print(f"сейчас {now:%H:%M} UTC, квота Google обновится в {QUIET_BEFORE_UTC}:00 — рано")
        out.append("which=none")
    else:
        try:
            state = json.load(open(STATE))
        except Exception:
            state = {}
        overdue = {}
        for h, every in EVERY_H.items():
            last = state.get(h)
            if not last:
                overdue[h] = 999.0
                print(f"  {h}: прогонов ещё не было — пора")
                continue
            hrs = (now - datetime.fromisoformat(last)).total_seconds() / 3600
            overdue[h] = hrs / every
            print(f"  {h}: с прошлого прогона {hrs:.1f} ч при норме {every} ч"
                  f" → {'пора' if hrs >= every else 'рано'}")
        due = [h for h, ratio in overdue.items() if ratio >= 1.0]
        if not due:
            out.append("which=none")
        else:
            # Если пора обеим, берём ту, что просрочена сильнее ОТНОСИТЕЛЬНО своей нормы,
            # иначе частая гипотеза всегда оттесняла бы редкую.
            pick = max(due, key=lambda h: overdue[h])
            print(f"  → работает: {pick}")
            out.append(f"which={pick}")
    gh = os.environ.get("GITHUB_OUTPUT")
    if gh:
        with open(gh, "a") as f:
            f.write("\n".join(out) + "\n")
    else:
        print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
