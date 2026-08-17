ContestResult.delete_all
Contest.delete_all
Person.delete_all

roster = [
  [ "Nomsa", "Dlamini" ], [ "Pieter", "van Wyk" ], [ "Aisha", "Patel" ],
  [ "Thabo", "Mokoena" ], [ "Ruth", "Coetzee" ], [ "Sipho", "Ndlovu" ],
  [ "Hannah", "Botha" ], [ "Kagiso", "Mahlangu" ], [ "Yusuf", "Adams" ],
  [ "Lerato", "Khumalo" ], [ "Willem", "Fourie" ], [ "Zanele", "Ngcobo" ],
  [ "Divya", "Naidoo" ], [ "Andries", "Steyn" ]
]

people = roster.each_with_index.map do |(name, surname), index|
  CreatePerson.call(
    name: name,
    surname: surname,
    email: "#{name.downcase}.#{surname.downcase.delete(" ")}@example.test",
    born_on: Date.new(1990, 1, 1) + index.years,
    joined_on: Date.new(2026, 1, 1) + index.days
  )
end

CreateContest.call(
  played_at: LocalZone.zone.parse("2026-03-03 18:00"),
  winner: people.last, loser: people.first, tie: false
)

CreateContest.call(
  played_at: LocalZone.zone.parse("2026-03-05 19:30"),
  winner: people[1], loser: people[4], tie: true
)

[
  [ 9, 2, "2026-03-12 18:30", false ],
  [ 5, 11, "2026-03-10 19:00", false ],
  [ 3, 8, "2026-03-10 18:00", true ],
  [ 12, 6, "2026-03-17 18:45", false ],
  [ 7, 13, "2026-03-19 19:15", false ],
  [ 10, 4, "2026-03-17 20:00", true ],
  [ 2, 9, "2026-03-24 18:30", false ],
  [ 13, 1, "2026-03-26 19:30", false ],
  [ 6, 10, "2026-03-31 18:15", false ]
].each do |winner, loser, at, tie|
  CreateContest.call(
    played_at: LocalZone.zone.parse(at),
    winner: people[winner], loser: people[loser], tie: tie
  )
end

puts "Seeded #{Person.count} people and #{Contest.count} contests."
