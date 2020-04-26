#!/usr/local/bin/ruby25

require 'pp'

lines = `cdio cddbinfo`.split("\n")

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

ad = lines[0].split('/', 2)

artist = neuter(ARGV[0] || ad[0])
disc = neuter(ARGV[1] || ad[1])

tracks = lines[2..-1]
  .collect { |l|
    m = l.match(/^ *(\d+) +([0-9:.]+) +(.+)$/)
    m ?
      { n: m[1].to_i, n2: '%02d' % m[1].to_i, d: m[2], t: m[3].strip } :
      nil }
  .compact

c = tracks.count

tracks = tracks.select { |t| t[:n] <= c }

tracks
  .each do |t|

    fn = [ artist, disc, t[:n2], t[:d], neuter(t[:t]) ].join('__')

    system("cdio cdrip #{t[:n]}")
    system("chmod go+r track#{t[:n2]}.wav")
    system("chmod g+w track#{t[:n2]}.wav")
    system("mv track#{t[:n2]}.wav #{fn}.wav")
  end

