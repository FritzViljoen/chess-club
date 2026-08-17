# Enough people and contests to see the ranking move. Runs through the services,
# so seeding exercises the same path the application does.
Contest.destroy_all
Person.destroy_all

people = %w[ Ann Bo Cy Di El Fay Gus ].each_with_index.map do |name, index|
  CreatePerson.call(
    name: name,
    surname: "Player#{index}",
    email: "#{name.downcase}@example.test",
    born_on: Date.new(1990, 1, 1) + index.years,
    joined_on: Date.new(2026, 1, 1) + index.days
  ).value
end

# The brief's worked example: the last person beats the first, so they climb half
# the gap and the loser drops one.
CreateContest.call(
  played_at: LocalZone.zone.parse("2026-03-03 18:00"),
  winner: people.last, loser: people.first, tie: false
)

# A tie between people who are not adjacent: the lower one gains a place.
CreateContest.call(
  played_at: LocalZone.zone.parse("2026-03-05 19:30"),
  winner: people[1], loser: people[4], tie: true
)

puts "Seeded #{Person.count} people and #{Contest.count} contests."
