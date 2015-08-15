#!/usr/bin/ruby

# Alex Standke
#   Aug 2015

# branch.rb
#  Helps you pick git branches. Total hack.

require 'io/console'
require 'colorize'
require 'curses'
require 'fuzzy_match'
include Curses

init_screen
start_color
init_pair(COLOR_GREEN, COLOR_GREEN, COLOR_BLACK)
init_pair(COLOR_BLUE, COLOR_BLUE, COLOR_BLACK)

GIT_BRANCH = `git branch`.split("\n")
exit 0 if GIT_BRANCH.size == 0

def read_char
  STDIN.echo = false
  STDIN.raw!

  input = STDIN.getc.chr
  if input == "\e" then
    input << STDIN.read_nonblock(3) rescue nil
    input << STDIN.read_nonblock(2) rescue nil
  end
ensure
  STDIN.echo = true
  STDIN.cooked!

  return input
end

def find_in_arr(arr, str)
  # simple, fast, for accurate typists
  q = str.downcase
  arr.map(&:downcase).each_with_index do |elem, i|
    return i if elem.include?(q)
  end

  # less fast, more forgiving
  matched_branch = FuzzyMatch.new(arr).find(str)
  return -1 if matched_branch.nil?
  arr.index(matched_branch)
end

def draw_branches(selected, state, search_str)
  setpos(0, 0)
  addstr("Pick a branch\n")

  branches = GIT_BRANCH.each_with_index.map do |branch, i|
    attron(color_pair(COLOR_BLUE) | A_BOLD) do
      addstr("#{ i == selected ? '> ' : '  ' }")
    end

    branch_name = branch.gsub('  ', '')
    if branch_name.include?('* ')
      branch_name = branch_name.gsub('* ', '')
      attron(color_pair(COLOR_GREEN)) { addstr("#{branch_name}\n") }
    else
      addstr("#{branch_name}\n")
    end

    branch_name
  end

  case state
  when :default
    addstr("Use j/k and enter to select. Use / to search. Hit m for master.\n")
  when :search
    addstr("/#{search_str}\n")
  end
  refresh
  branches
end

selected = 0

state = :default
search_str = ''
branches = draw_branches(selected, state, search_str)

loop do
  c = read_char

  case state
  when :default
    case c.downcase
    when "\r", 'f'
      close_screen
      `git checkout #{branches[selected]}`
      exit 0
    when "\e[A", 'k'
      selected -= 1
    when "\e[B", 'j'
      selected += 1
    when '/'
      state = :search
    when 'm'
      close_screen
      `git checkout master`
      exit 0
    when "\e", "\u0003", 'q'
      close_screen
      exit 0
    end
  when :search
    case c
    when "\e", "\u0003"
      search_str = ''
      state = :default
    when "\e[A"
      selected -= 1
    when "\e[B"
      selected += 1
    when "\u007F"
      state = :default if search_str.size == 0
      search_str = search_str[0...-1]
      selected = find_in_arr(branches, search_str)
    when "\r"
      close_screen
      `git checkout #{branches[selected]}`
      exit 0
    else
      search_str += c
      selected = find_in_arr(branches, search_str)
    end
  end

  selected = selected % branches.size

  draw_branches(selected, state, search_str)
end
