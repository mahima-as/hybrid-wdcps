from collections import defaultdict


def find(lst, key, value):
    for i, dic in enumerate(lst):
        if dic[key] == value:
            return i