#!/usr/local/bin/ruby25

require 'pp'

info = `cdio cddbinfo`.split("\n")

# ["Anton Batagov / Die Kunst der Fuga CD1(classical)",
#  "-------------------------------------------------",
#  "    1   5:20.60  Contrapunctus 1",
#  "    2   5:45.65  Contrapunctus 2",
#  "    3   4:57.68  Contrapunctus 3",
#  "    4   9:21.50  Contrapunctus 4",
#  "    5   6:09.62  Contrapunctus 5",
#  "    6   5:29.68  Contrapunctus 6",
#  "    7   4:15.57  Contrapunctus 7",
#  "    8  12:36.50  Contrapunctus 8",
#  "    9   8:48.55  Contrapunctus 9",
#  "   10   7:25.23  Canon per Augmentationem in Contrario Motu",
#  "   11   4:34.00  Canon alla Ottava",
#  "  170  74:48.33  "]

def neuter(s)
  s.strip.gsub(/[^a-zA-Z0-9]/, '_')
end

ad = info[0].split('/', 2)

opts, args = ARGV.partition { |a| a.match(/^-/) }

artist = neuter(args[0] || ad[0])
disc = neuter(args[1] || ad[1])

wet = ! opts.include?('--dry')

#
# go

if wet
  system("mkdir -p #{artist}/#{disc}/")
  system("chmod g+w #{artist}/")
  system("chmod go+r #{artist}/")
  system("chmod g+w #{artist}/#{disc}/")
  system("chmod go+r #{artist}/#{disc}/")
  File.open("#{artist}/#{disc}/#{artist}__#{disc}__info.txt", "wb") do |f|
    f.write(info.join("\n"))
  end
end

tracks = info[2..-1]
  .collect { |l|
    if m = l.match(/^ *(\d+) +([0-9:.]+) +(.+)$/)
      n = m[1].to_i
      n2 = '%02d' % m[1].to_i
      d = m[2]
      d2 = d.gsub(':', 'h').gsub('.', 'm') + 's'
      t = m[3].strip
      fn = [ artist, disc, n2, neuter(t) ].join('__')
      pa = File.join(artist, disc, fn)
      { n: n, n2: n2, d: d, d2: d2, t: t, fn: fn, pa: pa }
    else
      nil
    end }
  .compact

c = tracks.count
tracks = tracks.select { |t| t[:n] <= c }
pp tracks

tracks
  .each { |t|

    w = File.exist?("#{t[:fn]}.wav")
    f0 = File.exist?("#{t[:fn]}.flac")
    f1 = File.exist?("#{t[:pa]}.flac")

    if wet
      unless w || f0 || f1
        system("cdio cdrip #{t[:n]}")
        system("chmod go+r track#{t[:n2]}.wav")
        system("chmod g+w track#{t[:n2]}.wav")
        system("mv track#{t[:n2]}.wav #{t[:fn]}.wav")
      end
    else
      puts "#{t[:fn]}.wav"
    end }
  .each { |t|

    if wet
      system("flac #{t[:fn]}.wav") unless f0 || f1
      system("mv #{t[:fn]}.flac #{t[:pa]}.flac") unless f1
    end }

