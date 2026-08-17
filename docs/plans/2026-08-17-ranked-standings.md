# Ranked standings implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A Rails application that stores people and the contests between them,
derives a 1..n ranking from that log, and shows it.

**Architecture:** Contests are an append-only log entered out of play order.
Positions are never written directly: `CalculateStandings` takes every person and
every contest result as plain arrays and answers with an ordered list of person
ids; `WriteStandingsCache` persists that list to `standings_cache` as 1..n. Every
write service does its own change, then recomputes in the same transaction.

**Tech Stack:** Rails 8.1, SQLite, Minitest, Propshaft, Hotwire. No new gems.

**Spec:** [`docs/specs/2026-08-17-ranked-standings-design.md`](../specs/2026-08-17-ranked-standings-design.md)

## Global Constraints

Every task's requirements implicitly include these. All are enforced by cops that
fail `bin/ci` except where noted.

- **Branch from `main`.** `Service`, `Result`, `TypedArguments`, `TypedParams`
  and `Boolean` are all there. No new gems.
- **Banned terms** in `app/**`, `db/**`, `lib/**` — identifiers, comments *and*
  strings: `member`, `members`, `club`, `clubs`, `league`, `leagues`, `game`,
  `games`, `rating`, `ratings`, `team`, `teams`. Matching splits on separators
  and case humps. `test/` is exempt. Guard: `Vocabulary/BannedTerms`.
- **Every column `NOT NULL`.** Guard: `Schema/NoNullableColumns`.
- **No column defaults.** `created_at`/`updated_at` excepted. Guard:
  `Schema/NoColumnDefaults`.
- **No lifecycle callbacks** in models or their concerns — no `before_save`,
  `after_create`, `after_commit`, or siblings. Association options like
  `dependent: :destroy` are the framework's own and are fine. Guard:
  `Model/NoCallbacks`.
- **Every service argument typed at construction.** Hand-written `initialize`,
  every keyword through `typed` / `typed_array` / `typed_enum` / `typed_hash`. No
  `**options`, no positional parameters. Guard: `Service/NoUnguardedArguments`.
- **`call` returns a `Result`.** `success(value)` or `failure(:code)`.
  `Service.call` raises `TypeError` otherwise.
- **No inline param parsing in controllers.** Dates and times come from
  `TypedParams`. Guard: `Controller/NoInlineParamParse`.
- **A time names its zone.** `time_param!` takes a required `time_zone:`; a
  service asserts `ActiveSupport::TimeWithZone`, never `Time` or `DateTime`.
- **Test paths mirror constants**, not source paths. `CalculateStandings` →
  `test/services/calculate_standings_test.rb`.
- **Commit subject is one line.** No body, no trailers, no attribution.
- **Verify with `bin/ci`** before the final commit of each task; `bin/rails test`
  is enough between steps.

---

## File structure

| File | Responsibility |
| --- | --- |
| `db/migrate/*_create_people.rb` | `people` table |
| `app/models/person.rb` | a person; validations only |
| `db/migrate/*_create_contests.rb` | `contests` table |
| `db/migrate/*_create_contest_results.rb` | `contest_results` table |
| `app/models/contest.rb` | a contest; the exactly-two and has-a-winner rules |
| `app/models/contest_result.rb` | one person's place in one contest |
| `app/models/local_zone.rb` | the one IANA zone name, read by models and controllers |
| `db/migrate/*_create_standings_cache.rb` | `standings_cache` table |
| `app/models/standings_cache.rb` | the derived row; names its table explicitly |
| `app/services/calculate_standings.rb` | **all the ranking rules.** No database |
| `app/services/write_standings_cache.rb` | persists an order as 1..n |
| `app/services/create_person.rb` etc. | one write operation each, then recompute |
| `app/services/read_standings.rb` | the ordered rows for the view |
| `app/controllers/people_controller.rb` | people CRUD at the seam |
| `app/controllers/contests_controller.rb` | contest CRUD at the seam |
| `app/controllers/standings_controller.rb` | one page |
| `docs/decisions/*.md` | the three records the spec calls for |

---

### Task 1: `Person`

**Files:**
- Create: `db/migrate/<timestamp>_create_people.rb`
- Create: `app/models/person.rb`
- Test: `test/models/person_test.rb`
- Modify: `test/fixtures/people.yml` (created by the generator)

**Interfaces:**
- Consumes: nothing.
- Produces: `Person` with `name`, `surname`, `email`, `born_on` (Date),
  `joined_on` (Date), all non-null. `email` is optional — absent means `''`, not
  `NULL` — and unique among the people who have one.

- [ ] **Step 1: Generate the migration**

```bash
bin/rails generate migration CreatePeople
```

- [ ] **Step 2: Replace the migration body**

Every column is `NOT NULL` and none carries a default. A fresh table may declare
`null: false` at creation — the nullable-then-promote dance is only for adding a
column to a populated table.

```ruby
class CreatePeople < ActiveRecord::Migration[8.1]
  def change
    create_table :people do |t|
      t.string :name, null: false
      t.string :surname, null: false
      t.string :email, null: false
      t.date :born_on, null: false
      t.date :joined_on, null: false

      t.timestamps
    end

    # Partial, because email is optional and no column is nullable: somebody
    # without one holds '', and a plain unique index would let the first such
    # person in and refuse the second. Unique among the people who have one.
    add_index :people, :email, unique: true, where: "email != ''"
  end
end
```

- [ ] **Step 3: Run the migration**

```bash
bin/rails db:migrate
```

- [ ] **Step 4: Write the failing test**

Create `test/models/person_test.rb`:

```ruby
require "test_helper"

class PersonTest < ActiveSupport::TestCase
  test "is valid with every attribute present" do
    assert person.valid?, "expected a fully populated person to be valid"
  end

  test "refuses a blank name" do
    subject = person(name: "")

    assert_not subject.valid?, "expected a blank name to be refused"
    assert_includes subject.errors[:name], "can't be blank"
  end

  test "refuses a duplicate email" do
    person.save!
    duplicate = person(email: "ann@example.test")

    assert_not duplicate.valid?, "expected a repeated email to be refused"
  end

  test "allows more than one person without an email" do
    person(email: "").save!
    second = person(email: "")

    assert second.valid?, "expected a blank email to be exempt from uniqueness"
    assert second.save, "expected the partial index to let a second blank through"
  end

  test "starts with a blank email rather than nothing" do
    assert_equal "", Person.new.email, "expected the model to supply the starting value"
  end

  private
    def person(**overrides)
      Person.new(
        name: "Ann",
        surname: "Baker",
        email: "ann@example.test",
        born_on: Date.new(1990, 4, 2),
        joined_on: Date.new(2026, 1, 5),
        **overrides
      )
    end
end
```

- [ ] **Step 5: Run it and watch it fail**

```bash
bin/rails test test/models/person_test.rb
```

Expected: FAIL — `Person` is not defined.

- [ ] **Step 6: Write the model**

Create `app/models/person.rb`:

```ruby
# Somebody the standings rank. Holds no ranking rule: a position is derived from
# the contest log by CalculateStandings, never stored here.
class Person < ApplicationRecord
  # Email is optional, and no column here is nullable — so "no email" is '' and
  # never NULL, one way to say it instead of two. The starting value lives here
  # because no column carries a database default.
  attribute :email, :string, default: ""

  has_many :contest_results, dependent: :destroy

  validates :name, :surname, :born_on, :joined_on, presence: true
  validates :email, uniqueness: true, allow_blank: true
end
```

- [ ] **Step 7: Confirm no fixture was generated**

```bash
ls test/fixtures
```

Expected: `files` and nothing else. `generate migration` writes no fixture — only
`generate model` does — so there is nothing here to empty. Every test in this
plan builds the records it needs, which is what a fixture would otherwise be a
second source of.

- [ ] **Step 8: Run the tests and watch them pass**

```bash
bin/rails test test/models/person_test.rb
```

Expected: 5 runs, 0 failures.

- [ ] **Step 9: Run the full build**

```bash
bin/ci
```

Expected: every step green.

- [ ] **Step 10: Commit**

```bash
git add db/ app/models/person.rb test/
git commit -m "Add the person record"
```

---

### Task 2: `Contest` and `ContestResult`

**Files:**
- Create: `db/migrate/<timestamp>_create_contests.rb`
- Create: `db/migrate/<timestamp>_create_contest_results.rb`
- Create: `app/models/contest.rb`, `app/models/contest_result.rb`
- Test: `test/models/contest_test.rb`, `test/models/contest_result_test.rb`

**Interfaces:**
- Consumes: `Person` from Task 1.
- Produces: `Contest` with `played_at` (datetime) and `has_many
  :contest_results`; `ContestResult` with `contest_id`, `person_id`, `place`
  (Integer, 1 is best). `Contest` refuses anything but exactly two results, a set
  with no `place` of 1, and a `played_at` before somebody joined. Also
  `LocalZone::NAME` (an IANA string) and `LocalZone.zone`, the one zone this
  application reads dates and times in.

- [ ] **Step 1: Generate both migrations**

```bash
bin/rails generate migration CreateContests
bin/rails generate migration CreateContestResults
```

- [ ] **Step 2: Write the contests migration**

```ruby
class CreateContests < ActiveRecord::Migration[8.1]
  def change
    create_table :contests do |t|
      t.datetime :played_at, null: false

      t.timestamps
    end

    add_index :contests, :played_at
  end
end
```

- [ ] **Step 3: Write the contest results migration**

```ruby
class CreateContestResults < ActiveRecord::Migration[8.1]
  def change
    create_table :contest_results do |t|
      t.references :contest, null: false, foreign_key: true
      t.references :person, null: false, foreign_key: true
      t.integer :place, null: false

      t.timestamps
    end

    add_index :contest_results, [ :contest_id, :person_id ], unique: true
  end
end
```

- [ ] **Step 4: Run the migrations**

```bash
bin/rails db:migrate
```

- [ ] **Step 5: Name the zone, once**

A contest carries a moment, and a moment has to be read somewhere. The zone is
named here rather than taken from an ambient `Time.zone`, and both the models and
the controllers reach for this one constant.

Create `app/models/local_zone.rb`:

```ruby
# The one zone this application reads dates and times in. Named explicitly and in
# a single place: an ambient Time.zone is a zone nobody chose
# (constitution → `a-time-names-its-zone`).
module LocalZone
  NAME = "Africa/Johannesburg"

  def self.zone
    ActiveSupport::TimeZone[NAME]
  end
end
```

- [ ] **Step 6: Write the failing tests**

Create `test/models/contest_test.rb`:

```ruby
require "test_helper"

class ContestTest < ActiveSupport::TestCase
  test "is valid with two results and a winner" do
    assert contest.valid?, "expected two results with a first place to be valid"
  end

  test "is valid with two results that tie" do
    assert contest(places: [ 1, 1 ]).valid?, "expected a tie to be valid"
  end

  test "refuses a single result" do
    subject = contest(places: [ 1 ])

    assert_not subject.valid?, "expected one result to be refused"
    assert_includes subject.errors[:contest_results], "must be exactly two"
  end

  test "refuses three results" do
    subject = contest(places: [ 1, 2, 3 ])

    assert_not subject.valid?, "expected three results to be refused"
    assert_includes subject.errors[:contest_results], "must be exactly two"
  end

  test "refuses two results with the same person" do
    person = new_person("ann@example.test")
    subject = Contest.new(played_at: Time.utc(2026, 3, 3, 18, 0))
    subject.contest_results.build(person: person, place: 1)
    subject.contest_results.build(person: person, place: 2)

    assert_not subject.valid?, "expected one person twice to be refused"
    assert_includes subject.errors[:contest_results], "must name two different people"
  end

  test "refuses results where nobody finished first" do
    subject = contest(places: [ 2, 3 ])

    assert_not subject.valid?, "expected a set with no first place to be refused"
    assert_includes subject.errors[:contest_results], "must include a first place"
  end

  test "refuses a contest played before somebody joined" do
    subject = contest
    subject.played_at = LocalZone.zone.parse("2025-12-31 18:00")

    assert_not subject.valid?, "expected a contest predating a participant to be refused"
    assert_includes subject.errors[:played_at], "cannot be before somebody joined"
  end

  test "accepts a contest played on the day somebody joined" do
    subject = contest
    subject.played_at = LocalZone.zone.parse("2026-01-05 09:00")

    assert subject.valid?, "expected the join date itself to be early enough"
  end

  private
    def contest(places: [ 1, 2 ])
      subject = Contest.new(played_at: Time.utc(2026, 3, 3, 18, 0))

      places.each_with_index do |place, index|
        subject.contest_results.build(person: new_person("p#{index}@example.test"), place: place)
      end

      subject
    end

    def new_person(email)
      Person.create!(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5)
      )
    end
end
```

Create `test/models/contest_result_test.rb`:

```ruby
require "test_helper"

class ContestResultTest < ActiveSupport::TestCase
  test "refuses a place below one" do
    subject = ContestResult.new(place: 0)

    assert_not subject.valid?, "expected place 0 to be refused"
    assert_includes subject.errors[:place], "must be greater than 0"
  end
end
```

- [ ] **Step 7: Run them and watch them fail**

```bash
bin/rails test test/models/contest_test.rb test/models/contest_result_test.rb
```

Expected: FAIL — `Contest` is not defined.

- [ ] **Step 8: Write both models**

Create `app/models/contest.rb`:

```ruby
# One occasion on which people were placed against each other. Two today; the
# results are a collection so that more than two costs a validation change and
# not a migration.
class Contest < ApplicationRecord
  PARTICIPANTS = 2

  has_many :contest_results, dependent: :destroy
  has_many :people, through: :contest_results

  validates :played_at, presence: true
  validate :two_different_people
  validate :somebody_finished_first
  validate :played_after_everybody_joined

  private
    def two_different_people
      if contest_results.size != PARTICIPANTS
        errors.add(:contest_results, "must be exactly two")
      elsif contest_results.map(&:person_id).uniq.size != PARTICIPANTS
        errors.add(:contest_results, "must name two different people")
      end
    end

    def somebody_finished_first
      return if contest_results.any? { |result| result.place == 1 }

      errors.add(:contest_results, "must include a first place")
    end

    # The fold does not need this — seeding puts everybody in place before any
    # contest applies — but a contest predating a participant is bad data. The
    # day itself is early enough: somebody who joined this morning can play this
    # afternoon.
    def played_after_everybody_joined
      return if played_at.blank?

      played_on = played_at.in_time_zone(LocalZone::NAME).to_date
      return if contest_results.all? { |result| result.person.blank? || played_on >= result.person.joined_on }

      errors.add(:played_at, "cannot be before somebody joined")
    end
end
```

Create `app/models/contest_result.rb`:

```ruby
# Where one person finished in one contest. 1 is best; two results sharing a
# place are a tie.
class ContestResult < ApplicationRecord
  belongs_to :contest
  belongs_to :person

  validates :place, numericality: { only_integer: true, greater_than: 0 }
end
```

- [ ] **Step 9: Run the tests and watch them pass**

```bash
bin/rails test test/models/
```

Expected: 14 runs, 0 failures.

- [ ] **Step 10: Run the full build and commit**

```bash
bin/ci
git add db/ app/models/ test/
git commit -m "Add the contest log"
```

---

### Task 3: `CalculateStandings`

This is the whole domain. It touches no database: it takes arrays, reads
attributes off them, and answers with an array of ids. Every test below builds
records with `.new` and never saves one.

**Files:**
- Create: `app/services/calculate_standings.rb`
- Test: `test/services/calculate_standings_test.rb`

**Interfaces:**
- Consumes: `Person` (Task 1), `ContestResult` and `Contest` (Task 2).
- Produces: `CalculateStandings.call(people:, contest_results:)` →
  `success(Array<Integer>)`, person ids in position order, position 1 first.
  `contest_results` must have their `contest` already loaded; the service reads
  `result.contest.played_at` and never queries.

- [ ] **Step 1: Write the failing test for seeding**

Create `test/services/calculate_standings_test.rb`:

```ruby
require "test_helper"

class CalculateStandingsTest < ActiveSupport::TestCase
  test "seeds people in join order, earliest first" do
    order = calculate(people: [ person(2, "2026-02-01"), person(1, "2026-01-01") ])

    assert_equal [ 1, 2 ], order, "expected the earlier joiner to start ahead"
  end

  test "breaks a shared join date by id" do
    order = calculate(people: [ person(9, "2026-01-01"), person(4, "2026-01-01") ])

    assert_equal [ 4, 9 ], order, "expected the lower id to start ahead on a shared date"
  end

  private
    def calculate(people:, contest_results: [])
      CalculateStandings.call(people: people, contest_results: contest_results).value
    end

    def person(id, joined_on)
      Person.new(id: id, joined_on: Date.parse(joined_on))
    end
end
```

- [ ] **Step 2: Run it and watch it fail**

```bash
bin/rails test test/services/calculate_standings_test.rb
```

Expected: FAIL — `CalculateStandings` is not defined.

- [ ] **Step 3: Write enough of the service to seed**

Create `app/services/calculate_standings.rb`:

```ruby
# Every ranking rule, and nothing else. Arrays in, an array of person ids out —
# no query, no write, so each rule is exercised by handing in two literals.
class CalculateStandings < Service
  def initialize(people:, contest_results:)
    @people = typed_array(people, Person)
    @contest_results = typed_array(contest_results, ContestResult)
  end

  def call
    success(seed)
  end

  private
    # New people start last, so join order is the starting order.
    def seed
      @people.sort_by { |person| [ person.joined_on, person.id ] }.map(&:id)
    end
end
```

- [ ] **Step 4: Run the tests and watch them pass**

```bash
bin/rails test test/services/calculate_standings_test.rb
```

Expected: 2 runs, 0 failures.

- [ ] **Step 5: Commit the seed**

```bash
git add app/services/calculate_standings.rb test/services/
git commit -m "Seed the standings from join order"
```

- [ ] **Step 6: Write the failing tests for all three rules**

Append to `test/services/calculate_standings_test.rb`, inside the class and
above the `private` keyword:

```ruby
  test "nothing moves when the better-positioned person wins" do
    order = calculate(people: ladder(4), contest_results: contest(winner: 1, loser: 3))

    assert_equal [ 1, 2, 3, 4 ], order, "expected the expected result to move nobody"
  end

  test "a tie moves the worse-positioned person up one" do
    order = calculate(people: ladder(6), contest_results: contest(winner: 2, loser: 5, tie: true))

    assert_equal [ 1, 2, 3, 5, 4, 6 ], order, "expected the lower person to gain one place"
  end

  test "a tie between adjacent people moves nobody" do
    order = calculate(people: ladder(4), contest_results: contest(winner: 2, loser: 3, tie: true))

    assert_equal [ 1, 2, 3, 4 ], order, "expected adjacent people to stay put on a tie"
  end

  # The brief's own worked example: positions 10 and 16, the lower wins, and they
  # end on 11 and 13. Shifted to a seven-person ladder, that is positions 1 and 7
  # ending on 2 and 4.
  test "the brief's worked example" do
    order = calculate(people: ladder(7), contest_results: contest(winner: 7, loser: 1))

    assert_equal [ 2, 1, 3, 7, 4, 5, 6 ], order,
      "expected the loser on position 2 and the winner on position 4"
  end

  test "an odd gap rounds the climb down" do
    order = calculate(people: ladder(6), contest_results: contest(winner: 6, loser: 1))

    assert_equal [ 2, 1, 3, 6, 4, 5 ], order, "expected a climb of 2, not 3, from a gap of 5"
  end

  test "a gap of two demotes and caps the climb to nothing" do
    order = calculate(people: ladder(4), contest_results: contest(winner: 3, loser: 1))

    assert_equal [ 2, 1, 3, 4 ], order, "expected the demotion to win the contested slot"
  end

  test "adjacent people exchange places when the lower wins" do
    order = calculate(people: ladder(4), contest_results: contest(winner: 3, loser: 2))

    assert_equal [ 1, 3, 2, 4 ], order, "expected an exchange when the gap is one"
  end

  test "contests apply in played order, not the order they were handed over" do
    late = contest(winner: 4, loser: 1, at: "2026-03-05 18:00", contest_id: 2)
    early = contest(winner: 3, loser: 1, at: "2026-03-03 18:00", contest_id: 1)

    assert_equal calculate(people: ladder(4), contest_results: late + early),
      calculate(people: ladder(4), contest_results: early + late),
      "expected the same standings whichever order the results arrived in"
  end
```

And replace the `private` helpers with:

```ruby
  private
    def calculate(people:, contest_results: [])
      CalculateStandings.call(people: people, contest_results: contest_results).value
    end

    def person(id, joined_on)
      Person.new(id: id, joined_on: Date.parse(joined_on))
    end

    # Ids 1..size, joining a day apart, so the starting order is 1, 2, 3...
    def ladder(size)
      (1..size).map { |id| person(id, "2026-01-#{format("%02d", id)}") }
    end

    # Two results for one contest. `winner` and `loser` are person ids; a tie
    # gives both first place, so which is named which stops mattering.
    def contest(winner:, loser:, tie: false, at: "2026-03-03 18:00", contest_id: 1)
      record = Contest.new(id: contest_id, played_at: Time.utc(*at.split(/[- :]/).map(&:to_i)))

      [
        ContestResult.new(contest: record, contest_id: contest_id, person_id: winner, place: 1),
        ContestResult.new(contest: record, contest_id: contest_id, person_id: loser, place: tie ? 1 : 2)
      ]
    end
```

- [ ] **Step 7: Run them and watch them fail**

```bash
bin/rails test test/services/calculate_standings_test.rb
```

Expected: FAIL on every new test — the service ignores `contest_results`.

- [ ] **Step 8: Implement the rules**

Replace `app/services/calculate_standings.rb` with:

```ruby
# Every ranking rule, and nothing else. Arrays in, an array of person ids out —
# no query, no write, so each rule is exercised by handing in two literals.
#
# `contest_results` arrive with their contest already loaded; this reads
# `played_at` off it and never goes back to the database for anything.
class CalculateStandings < Service
  def initialize(people:, contest_results:)
    @people = typed_array(people, Person)
    @contest_results = typed_array(contest_results, ContestResult)
  end

  def call
    success(contests.reduce(seed) { |order, results| apply(order, results) })
  end

  private
    # New people start last, so join order is the starting order.
    def seed
      @people.sort_by { |person| [ person.joined_on, person.id ] }.map(&:id)
    end

    # The results grouped into contests, oldest first. `contest_id` breaks a
    # shared moment: the fold has to be deterministic and two rows sharing one
    # have no other order.
    def contests
      @contest_results
        .group_by(&:contest_id)
        .values
        .sort_by { |results| [ results.first.contest.played_at, results.first.contest_id ] }
    end

    def apply(order, results)
      better, worse = results.sort_by { |result| order.index(result.person_id) }
      return order if better.place < worse.place

      a = order.index(better.person_id)
      b = order.index(worse.person_id)

      better.place == worse.place ? tie(order, b, b - a) : win_from_behind(order, a, b, b - a)
    end

    # The lower person gains one place, unless there is no room between them.
    def tie(order, b, gap)
      gap == 1 ? order : move(order, b, b - 1)
    end

    # The better-positioned person drops one place. The winner then climbs half
    # the gap, rounded down, measured from where both started.
    #
    # The two moves collide only at a gap of two, where both want the one slot
    # between the players. The drop is stated unconditionally by the brief and
    # the climb is already an approximation, so the climb is what gives.
    def win_from_behind(order, a, b, gap)
      dropped = move(order, a, a + 1)
      target = b - gap / 2

      target <= a + 1 ? dropped : move(dropped, dropped.index(order[b]), target)
    end

    # Everyone between the two indices shifts by one to fill in.
    def move(order, from, to)
      moved = order.dup
      moved.insert(to, moved.delete_at(from))
      moved
    end
end
```

- [ ] **Step 9: Run the tests and watch them pass**

```bash
bin/rails test test/services/calculate_standings_test.rb
```

Expected: 10 runs, 0 failures.

- [ ] **Step 10: Run the full build and commit**

```bash
bin/ci
git add app/services/calculate_standings.rb test/services/
git commit -m "Apply the ranking rules when folding the contest log"
```

---

### Task 4: `StandingsCache` and `WriteStandingsCache`

**Files:**
- Create: `db/migrate/<timestamp>_create_standings_cache.rb`
- Create: `app/models/standings_cache.rb`
- Create: `app/services/write_standings_cache.rb`
- Test: `test/services/write_standings_cache_test.rb`

**Interfaces:**
- Consumes: `Person` (Task 1).
- Produces: `StandingsCache` with `person_id` and `position`, table
  `standings_cache`. `WriteStandingsCache.call(order:)` where `order` is
  `Array<Integer>` of person ids → `success(order)`, having replaced every row.

- [ ] **Step 1: Generate and write the migration**

```bash
bin/rails generate migration CreateStandingsCache
```

No timestamps: these rows are replaced wholesale on every write and nothing ever
asks when one was made.

```ruby
class CreateStandingsCache < ActiveRecord::Migration[8.1]
  def change
    create_table :standings_cache do |t|
      t.references :person, null: false, foreign_key: true, index: { unique: true }
      t.integer :position, null: false
    end

    add_index :standings_cache, :position, unique: true
  end
end
```

- [ ] **Step 2: Run the migration**

```bash
bin/rails db:migrate
```

- [ ] **Step 3: Write the failing test**

Create `test/services/write_standings_cache_test.rb`:

```ruby
require "test_helper"

class WriteStandingsCacheTest < ActiveSupport::TestCase
  test "writes the order as positions counting from one" do
    people = [ person("a@example.test"), person("b@example.test") ]

    WriteStandingsCache.call(order: people.map(&:id))

    assert_equal people.map(&:id), StandingsCache.order(:position).pluck(:person_id),
      "expected the rows to come back in the order handed in"
    assert_equal [ 1, 2 ], StandingsCache.order(:position).pluck(:position),
      "expected positions to start at 1 and be contiguous"
  end

  test "replaces whatever was there before" do
    first = person("a@example.test")
    second = person("b@example.test")
    WriteStandingsCache.call(order: [ first.id, second.id ])

    WriteStandingsCache.call(order: [ second.id, first.id ])

    assert_equal [ second.id, first.id ], StandingsCache.order(:position).pluck(:person_id),
      "expected the second write to replace the first, not add to it"
    assert_equal 2, StandingsCache.count, "expected no rows left over from the first write"
  end

  test "empties the table when handed an empty order" do
    WriteStandingsCache.call(order: [ person("a@example.test").id ])

    WriteStandingsCache.call(order: [])

    assert_equal 0, StandingsCache.count, "expected an empty order to leave no rows"
  end

  private
    def person(email)
      Person.create!(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5)
      )
    end
end
```

- [ ] **Step 4: Run it and watch it fail**

```bash
bin/rails test test/services/write_standings_cache_test.rb
```

Expected: FAIL — `WriteStandingsCache` is not defined.

- [ ] **Step 5: Write the model and the service**

Create `app/models/standings_cache.rb`:

```ruby
# One person's current position. Derived: WriteStandingsCache replaces every row
# from what CalculateStandings answered, and nothing else writes here.
class StandingsCache < ApplicationRecord
  self.table_name = "standings_cache"

  belongs_to :person
end
```

Create `app/services/write_standings_cache.rb`:

```ruby
# Replaces the derived standings with an order somebody else calculated. It holds
# no rule and does not know why the order is what it is.
class WriteStandingsCache < Service
  def initialize(order:)
    @order = typed_array(order, Integer)
  end

  def call
    StandingsCache.delete_all
    StandingsCache.insert_all(rows) if rows.any?

    success(@order)
  end

  private
    def rows
      @rows ||= @order.each_with_index.map do |person_id, index|
        { person_id: person_id, position: index + 1 }
      end
    end
end
```

- [ ] **Step 6: Run the tests and watch them pass**

```bash
bin/rails test test/services/write_standings_cache_test.rb
```

Expected: 3 runs, 0 failures.

- [ ] **Step 7: Run the full build and commit**

```bash
bin/ci
git add db/ app/models/standings_cache.rb app/services/write_standings_cache.rb test/
git commit -m "Persist the calculated standings to a cache table"
```

---

### Task 5: The person write services

Three operations, one class each. Each does its own change and then recomputes,
in one transaction, because a half-applied shuffle is worse than a refused one.

**Files:**
- Create: `app/services/create_person.rb`, `app/services/update_person.rb`,
  `app/services/remove_person.rb`
- Create: `app/services/recalculate_standings.rb`
- Test: `test/services/create_person_test.rb`,
  `test/services/remove_person_test.rb`

**Interfaces:**
- Consumes: `CalculateStandings` (Task 3), `WriteStandingsCache` (Task 4).
- Produces:
  - `RecalculateStandings.call` → `success(Array<Integer>)`. Loads both
    collections, calculates, writes. Takes no arguments.
  - `CreatePerson.call(name:, surname:, email:, born_on:, joined_on:)` →
    `success(Person)` or `failure(:invalid)`.
  - `UpdatePerson.call(person:, name:, surname:, email:, born_on:, joined_on:)` →
    `success(Person)` or `failure(:invalid)`.
  - `RemovePerson.call(person:)` → `success(Person)`.

- [ ] **Step 1: Write the failing tests**

Create `test/services/create_person_test.rb`:

```ruby
require "test_helper"

class CreatePersonTest < ActiveSupport::TestCase
  test "adds the person to the end of the standings" do
    first = create("a@example.test", "2026-01-01").value

    second = create("b@example.test", "2026-02-01").value

    assert_equal [ first.id, second.id ], StandingsCache.order(:position).pluck(:person_id),
      "expected a new person to start last"
  end

  test "refuses a duplicate email without touching the standings" do
    create("a@example.test", "2026-01-01")

    result = create("a@example.test", "2026-02-01")

    assert_not result.success?, "expected a repeated email to be refused"
    assert_equal :invalid, result.error
    assert_equal 1, StandingsCache.count, "expected a refusal to leave the standings alone"
  end

  test "seeds a back-dated joiner ahead of people who joined later" do
    late = create("b@example.test", "2026-02-01").value

    early = create("a@example.test", "2026-01-01").value

    assert_equal [ early.id, late.id ], StandingsCache.order(:position).pluck(:person_id),
      "expected join date to decide the order, not the order of entry"
  end

  private
    def create(email, joined_on)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.parse(joined_on)
      )
    end
end
```

Create `test/services/remove_person_test.rb`:

```ruby
require "test_helper"

class RemovePersonTest < ActiveSupport::TestCase
  test "removes the person, their results and the contests they were in" do
    ann = create("a@example.test")
    bob = create("b@example.test")
    record_contest(ann, bob)

    RemovePerson.call(person: ann)

    assert_equal 0, Person.where(id: ann.id).count, "expected the person to be gone"
    assert_equal 0, Contest.count, "expected a contest they played in to be gone"
    assert_equal 0, ContestResult.count, "expected the opponent's result to go with it"
  end

  test "closes the gap they left in the standings" do
    ann = create("a@example.test")
    bob = create("b@example.test")

    RemovePerson.call(person: ann)

    assert_equal [ [ bob.id, 1 ] ], StandingsCache.order(:position).pluck(:person_id, :position),
      "expected the remaining person to be position 1"
  end

  private
    def create(email)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 5)
      ).value
    end

    def record_contest(winner, loser)
      contest = Contest.new(played_at: Time.utc(2026, 3, 3, 18, 0))
      contest.contest_results.build(person: winner, place: 1)
      contest.contest_results.build(person: loser, place: 2)
      contest.save!
      contest
    end
end
```

- [ ] **Step 2: Run them and watch them fail**

```bash
bin/rails test test/services/create_person_test.rb test/services/remove_person_test.rb
```

Expected: FAIL — `CreatePerson` is not defined.

- [ ] **Step 3: Write the recompute**

Create `app/services/recalculate_standings.rb`:

```ruby
# Loads the whole log, calculates, and replaces the cache. Total every time: a
# few hundred rows folded in memory, and one code path that cannot disagree with
# itself.
#
# The contests are preloaded because CalculateStandings reads played_at off each
# result's contest and must not go looking for it a row at a time.
class RecalculateStandings < Service
  def call
    order = CalculateStandings.call(
      people: Person.all.to_a,
      contest_results: ContestResult.includes(:contest).to_a
    ).value

    WriteStandingsCache.call(order: order)
  end
end
```

- [ ] **Step 4: Write the three person services**

Create `app/services/create_person.rb`:

```ruby
class CreatePerson < Service
  def initialize(name:, surname:, email:, born_on:, joined_on:)
    @name = typed(name, String)
    @surname = typed(surname, String)
    @email = typed(email, String)
    @born_on = typed(born_on, Date)
    @joined_on = typed(joined_on, Date)
  end

  def call
    person = Person.new(
      name: @name, surname: @surname, email: @email,
      born_on: @born_on, joined_on: @joined_on
    )

    ApplicationRecord.transaction do
      return failure(:invalid) unless person.save

      RecalculateStandings.call
    end

    success(person)
  end
end
```

Create `app/services/update_person.rb`:

```ruby
class UpdatePerson < Service
  def initialize(person:, name:, surname:, email:, born_on:, joined_on:)
    @person = typed(person, Person)
    @name = typed(name, String)
    @surname = typed(surname, String)
    @email = typed(email, String)
    @born_on = typed(born_on, Date)
    @joined_on = typed(joined_on, Date)
  end

  def call
    ApplicationRecord.transaction do
      updated = @person.update(
        name: @name, surname: @surname, email: @email,
        born_on: @born_on, joined_on: @joined_on
      )
      return failure(:invalid) unless updated

      RecalculateStandings.call
    end

    success(@person)
  end
end
```

Create `app/services/remove_person.rb`:

```ruby
# A contest with one participant is not a contest, so the contests this person
# took part in go too. History naming a removed person does not survive them.
class RemovePerson < Service
  def initialize(person:)
    @person = typed(person, Person)
  end

  def call
    ApplicationRecord.transaction do
      Contest.where(id: @person.contest_results.select(:contest_id)).destroy_all
      @person.destroy!

      RecalculateStandings.call
    end

    success(@person)
  end
end
```

- [ ] **Step 5: Run the tests and watch them pass**

```bash
bin/rails test test/services/
```

Expected: all green.

- [ ] **Step 6: Run the full build and commit**

```bash
bin/ci
git add app/services/ test/services/
git commit -m "Add the person write operations and the recompute they trigger"
```

---

### Task 6: The contest write services

**Files:**
- Create: `app/services/create_contest.rb`, `app/services/update_contest.rb`,
  `app/services/remove_contest.rb`
- Test: `test/services/create_contest_test.rb`,
  `test/services/update_contest_test.rb`

**Interfaces:**
- Consumes: `RecalculateStandings` (Task 5), `LocalZone` (Task 2).
- Produces:
  - `CreateContest.call(played_at:, winner:, loser:, tie:)` → `success(Contest)`
    or `failure(:invalid)`. `played_at` is an `ActiveSupport::TimeWithZone`;
    `winner` and `loser` are `Person`; `tie` is a `Boolean`. On a tie both get
    place 1 and which is named `winner` stops mattering.
  - `UpdateContest.call(contest:, played_at:, winner:, loser:, tie:)` →
    `success(Contest)` or `failure(:invalid)`.
  - `RemoveContest.call(contest:)` → `success(Contest)`.

- [ ] **Step 1: Write the failing tests**

Create `test/services/create_contest_test.rb`:

```ruby
require "test_helper"

class CreateContestTest < ActiveSupport::TestCase
  test "moves the standings when the lower-placed person wins" do
    people = 4.times.map { |index| create_person("p#{index}@example.test", index) }

    CreateContest.call(played_at: at("2026-03-03 18:00"), winner: people[3], loser: people[0], tie: false)

    assert_equal [ people[1], people[0], people[3], people[2] ].map(&:id),
      StandingsCache.order(:position).pluck(:person_id),
      "expected the loser to drop one and the winner to climb one"
  end

  test "leaves the standings alone when the better-placed person wins" do
    people = 4.times.map { |index| create_person("p#{index}@example.test", index) }

    CreateContest.call(played_at: at("2026-03-03 18:00"), winner: people[0], loser: people[3], tie: false)

    assert_equal people.map(&:id), StandingsCache.order(:position).pluck(:person_id),
      "expected the expected result to move nobody"
  end

  test "refuses one person against themselves" do
    person = create_person("a@example.test", 0)

    result = CreateContest.call(played_at: at("2026-03-03 18:00"), winner: person, loser: person, tie: false)

    assert_not result.success?, "expected a person against themselves to be refused"
    assert_equal :invalid, result.error
  end

  private
    def at(literal)
      LocalZone.zone.parse(literal)
    end

    def create_person(email, offset)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 1) + offset
      ).value
    end
end
```

Create `test/services/update_contest_test.rb`:

```ruby
require "test_helper"

class UpdateContestTest < ActiveSupport::TestCase
  test "recomputes every position that followed the corrected contest" do
    people = 4.times.map { |index| create_person("p#{index}@example.test", index) }
    contest = CreateContest.call(
      played_at: at("2026-03-03 18:00"), winner: people[3], loser: people[0], tie: false
    ).value

    UpdateContest.call(
      contest: contest, played_at: at("2026-03-03 18:00"),
      winner: people[0], loser: people[3], tie: false
    )

    assert_equal people.map(&:id), StandingsCache.order(:position).pluck(:person_id),
      "expected correcting the outcome to undo the movement it caused"
  end

  test "removing a contest undoes it" do
    people = 4.times.map { |index| create_person("p#{index}@example.test", index) }
    contest = CreateContest.call(
      played_at: at("2026-03-03 18:00"), winner: people[3], loser: people[0], tie: false
    ).value

    RemoveContest.call(contest: contest)

    assert_equal people.map(&:id), StandingsCache.order(:position).pluck(:person_id),
      "expected the standings to return to the seed once the log was empty"
  end

  private
    def at(literal)
      LocalZone.zone.parse(literal)
    end

    def create_person(email, offset)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 1) + offset
      ).value
    end
end
```

- [ ] **Step 2: Run them and watch them fail**

```bash
bin/rails test test/services/create_contest_test.rb test/services/update_contest_test.rb
```

Expected: FAIL — `CreateContest` is not defined.

- [ ] **Step 3: Write the three contest services**

Create `app/services/create_contest.rb`:

```ruby
# A tie gives both people first place, so on a tie which one is named `winner`
# makes no difference to the outcome.
class CreateContest < Service
  def initialize(played_at:, winner:, loser:, tie:)
    @played_at = typed(played_at, ActiveSupport::TimeWithZone)
    @winner = typed(winner, Person)
    @loser = typed(loser, Person)
    @tie = typed(tie, Boolean)
  end

  def call
    contest = Contest.new(played_at: @played_at)
    contest.contest_results.build(person: @winner, place: 1)
    contest.contest_results.build(person: @loser, place: @tie ? 1 : 2)

    ApplicationRecord.transaction do
      return failure(:invalid) unless contest.save

      RecalculateStandings.call
    end

    success(contest)
  end
end
```

Create `app/services/update_contest.rb`:

```ruby
class UpdateContest < Service
  def initialize(contest:, played_at:, winner:, loser:, tie:)
    @contest = typed(contest, Contest)
    @played_at = typed(played_at, ActiveSupport::TimeWithZone)
    @winner = typed(winner, Person)
    @loser = typed(loser, Person)
    @tie = typed(tie, Boolean)
  end

  def call
    ApplicationRecord.transaction do
      @contest.contest_results.destroy_all
      @contest.played_at = @played_at
      @contest.contest_results.build(person: @winner, place: 1)
      @contest.contest_results.build(person: @loser, place: @tie ? 1 : 2)
      return failure(:invalid) unless @contest.save

      RecalculateStandings.call
    end

    success(@contest)
  end
end
```

Create `app/services/remove_contest.rb`:

```ruby
class RemoveContest < Service
  def initialize(contest:)
    @contest = typed(contest, Contest)
  end

  def call
    ApplicationRecord.transaction do
      @contest.destroy!

      RecalculateStandings.call
    end

    success(@contest)
  end
end
```

- [ ] **Step 4: Run the tests and watch them pass**

```bash
bin/rails test test/services/
```

Expected: all green.

- [ ] **Step 5: Run the full build and commit**

```bash
bin/ci
git add app/services/ test/services/
git commit -m "Add the contest write operations"
```

---

### Task 7: The people screens

**Files:**
- Create: `app/controllers/people_controller.rb`
- Create: `app/views/people/index.html.erb`, `show.html.erb`, `new.html.erb`,
  `edit.html.erb`, `_form.html.erb`
- Modify: `app/controllers/application_controller.rb`
- Modify: `config/routes.rb`
- Test: `test/controllers/people_controller_test.rb`

**Interfaces:**
- Consumes: `CreatePerson`, `UpdatePerson`, `RemovePerson` (Task 5),
  `LocalZone` (Task 2).
- Produces: RESTful `/people` routes.

- [ ] **Step 1: Let the controllers parse at the seam**

Modify `app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  include TypedParams

  allow_browser versions: :modern
end
```

- [ ] **Step 2: Add the routes**

Modify `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  resources :people
  resources :contests
  get "standings", to: "standings#show"

  get "up" => "rails/health#show", as: :rails_health_check

  root "standings#show"
end
```

- [ ] **Step 3: Write the failing controller test**

Create `test/controllers/people_controller_test.rb`:

```ruby
require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  test "creates a person and puts them in the standings" do
    post people_path, params: { person: attributes }

    assert_redirected_to people_path
    assert_equal 1, Person.count, "expected the person to be stored"
    assert_equal 1, StandingsCache.count, "expected the standings to be recomputed"
  end

  test "re-renders the form when the person is refused" do
    post people_path, params: { person: attributes(name: "") }

    assert_response :unprocessable_entity
    assert_equal 0, Person.count, "expected nothing to be stored"
  end

  test "bounces a date it cannot read" do
    post people_path, params: { person: attributes(joined_on: "not a date") }

    assert_response :redirect
    assert_equal 0, Person.count, "expected an unreadable date to store nothing"
  end

  test "removes a person" do
    post people_path, params: { person: attributes }

    delete person_path(Person.first)

    assert_redirected_to people_path
    assert_equal 0, Person.count, "expected the person to be gone"
  end

  private
    def attributes(**overrides)
      {
        name: "Ann", surname: "Baker", email: "ann@example.test",
        born_on: "1990-04-02", joined_on: "2026-01-05"
      }.merge(overrides)
    end
end
```

- [ ] **Step 4: Run it and watch it fail**

```bash
bin/rails test test/controllers/people_controller_test.rb
```

Expected: FAIL — no route or no controller.

- [ ] **Step 5: Write the controller**

Dates are parsed by `TypedParams` at the seam and nowhere else. `date_param!`
bounces unreadable input before any service is reached.

Create `app/controllers/people_controller.rb`:

```ruby
class PeopleController < ApplicationController
  before_action :find_person, only: %i[ show edit update destroy ]

  def index
    @people = Person.order(:surname, :name)
  end

  def show
  end

  def new
    @person = Person.new
  end

  def edit
  end

  def create
    result = CreatePerson.call(**submitted)
    return redirect_to people_path, notice: "Added." if result.success?

    @person = Person.new(**submitted)
    @person.valid?
    render :new, status: :unprocessable_entity
  end

  def update
    result = UpdatePerson.call(person: @person, **submitted)
    return redirect_to people_path, notice: "Saved." if result.success?

    render :edit, status: :unprocessable_entity
  end

  def destroy
    RemovePerson.call(person: @person)

    redirect_to people_path, notice: "Removed."
  end

  private
    def find_person
      @person = Person.find(params[:id])
    end

    def submitted
      details = params.require(:person).permit(:name, :surname, :email)

      {
        name: details[:name].to_s,
        surname: details[:surname].to_s,
        email: details[:email].to_s,
        born_on: date_param!(:born_on, time_zone: LocalZone::NAME),
        joined_on: date_param!(:joined_on, time_zone: LocalZone::NAME)
      }
    end
end
```

The date fields post at the top level rather than nested under `person`, because
`date_param!` reads `params[key]`. The form below names them accordingly.

- [ ] **Step 6: Write the views**

Create `app/views/people/_form.html.erb`:

```erb
<%= form_with model: person do |form| %>
  <% if person.errors.any? %>
    <ul class="errors">
      <% person.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  <% end %>

  <div><%= form.label :name %><%= form.text_field :name %></div>
  <div><%= form.label :surname %><%= form.text_field :surname %></div>
  <div><%= form.label :email %><%= form.email_field :email %></div>
  <div><%= label_tag :born_on, "Date of birth" %><%= date_field_tag :born_on, person.born_on %></div>
  <div><%= label_tag :joined_on, "Joined on" %><%= date_field_tag :joined_on, person.joined_on %></div>

  <%= form.submit %>
<% end %>
```

Create `app/views/people/index.html.erb`:

```erb
<h1>People</h1>

<p><%= link_to "Add somebody", new_person_path %></p>

<table>
  <thead>
    <tr><th>Name</th><th>Email</th><th>Joined</th><th>Contests</th><th></th></tr>
  </thead>
  <tbody>
    <% @people.each do |person| %>
      <tr>
        <td><%= link_to "#{person.name} #{person.surname}", person %></td>
        <td><%= person.email %></td>
        <td><%= person.joined_on.to_fs(:long) %></td>
        <td><%= person.contest_results.size %></td>
        <td>
          <%= link_to "Edit", edit_person_path(person) %>
          <%= button_to "Remove", person, method: :delete %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

Create `app/views/people/show.html.erb`:

```erb
<h1><%= @person.name %> <%= @person.surname %></h1>

<dl>
  <dt>Email</dt><dd><%= @person.email %></dd>
  <dt>Date of birth</dt><dd><%= @person.born_on.to_fs(:long) %></dd>
  <dt>Joined</dt><dd><%= @person.joined_on.to_fs(:long) %></dd>
  <dt>Contests played</dt><dd><%= @person.contest_results.size %></dd>
</dl>

<p><%= link_to "Edit", edit_person_path(@person) %> · <%= link_to "All people", people_path %></p>
```

Create `app/views/people/new.html.erb`:

```erb
<h1>Add somebody</h1>

<%= render "form", person: @person %>
```

Create `app/views/people/edit.html.erb`:

```erb
<h1>Edit <%= @person.name %> <%= @person.surname %></h1>

<%= render "form", person: @person %>
```

- [ ] **Step 7: Run the tests and watch them pass**

```bash
bin/rails test test/controllers/people_controller_test.rb
```

Expected: 4 runs, 0 failures.

- [ ] **Step 8: Look at it**

Start the app and take a screenshot of `/people` with two people added. Use the
`run` skill. A UI change ships with a screenshot.

- [ ] **Step 9: Run the full build and commit**

```bash
bin/ci
git add app/ config/routes.rb test/
git commit -m "Add the people screens"
```

---

### Task 8: The contest screens

**Files:**
- Create: `app/controllers/contests_controller.rb`
- Create: `app/views/contests/index.html.erb`, `new.html.erb`, `edit.html.erb`,
  `_form.html.erb`
- Test: `test/controllers/contests_controller_test.rb`

**Interfaces:**
- Consumes: `CreateContest`, `UpdateContest`, `RemoveContest` (Task 6),
  `LocalZone::NAME` (Task 7).
- Produces: RESTful `/contests` routes.

- [ ] **Step 1: Write the failing test**

Create `test/controllers/contests_controller_test.rb`:

```ruby
require "test_helper"

class ContestsControllerTest < ActionDispatch::IntegrationTest
  test "records a contest and moves the standings" do
    ann = create_person("ann@example.test", 0)
    bob = create_person("bob@example.test", 1)

    post contests_path, params: {
      played_at: "2026-03-03 18:00", contest: { winner_id: bob.id, loser_id: ann.id, tie: "0" }
    }

    assert_redirected_to contests_path
    assert_equal 1, Contest.count, "expected the contest to be stored"
    assert_equal [ bob.id, ann.id ], StandingsCache.order(:position).pluck(:person_id),
      "expected the winner to take first position"
  end

  test "records a tie" do
    ann = create_person("ann@example.test", 0)
    bob = create_person("bob@example.test", 1)

    post contests_path, params: {
      played_at: "2026-03-03 18:00", contest: { winner_id: ann.id, loser_id: bob.id, tie: "1" }
    }

    assert_equal [ 1, 1 ], ContestResult.order(:id).pluck(:place),
      "expected a tie to give both people first place"
  end

  test "bounces a time it cannot read" do
    ann = create_person("ann@example.test", 0)
    bob = create_person("bob@example.test", 1)

    post contests_path, params: {
      played_at: "half past nonsense", contest: { winner_id: bob.id, loser_id: ann.id, tie: "0" }
    }

    assert_response :redirect
    assert_equal 0, Contest.count, "expected an unreadable time to store nothing"
  end

  private
    def create_person(email, offset)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 1) + offset
      ).value
    end
end
```

- [ ] **Step 2: Run it and watch it fail**

```bash
bin/rails test test/controllers/contests_controller_test.rb
```

Expected: FAIL — no controller.

- [ ] **Step 3: Write the controller**

Create `app/controllers/contests_controller.rb`:

```ruby
class ContestsController < ApplicationController
  before_action :find_contest, only: %i[ edit update destroy ]

  def index
    @contests = Contest.includes(contest_results: :person).order(played_at: :desc, id: :desc)
  end

  def new
    @contest = Contest.new
    @people = Person.order(:surname, :name)
  end

  def edit
    @people = Person.order(:surname, :name)
  end

  def create
    result = CreateContest.call(**submitted)
    return redirect_to contests_path, notice: "Recorded." if result.success?

    @contest = Contest.new
    @people = Person.order(:surname, :name)
    render :new, status: :unprocessable_entity
  end

  def update
    result = UpdateContest.call(contest: @contest, **submitted)
    return redirect_to contests_path, notice: "Saved." if result.success?

    @people = Person.order(:surname, :name)
    render :edit, status: :unprocessable_entity
  end

  def destroy
    RemoveContest.call(contest: @contest)

    redirect_to contests_path, notice: "Removed."
  end

  private
    def find_contest
      @contest = Contest.find(params[:id])
    end

    def submitted
      details = params.require(:contest).permit(:winner_id, :loser_id, :tie)

      {
        played_at: time_param!(:played_at, time_zone: LocalZone::NAME),
        winner: Person.find(details[:winner_id]),
        loser: Person.find(details[:loser_id]),
        tie: boolean_param!(:tie)
      }
    end
end
```

`boolean_param!` reads `params[:tie]`, so the form posts `tie` at the top level
alongside `played_at`. Adjust the form below to match.

- [ ] **Step 4: Write the views**

Create `app/views/contests/_form.html.erb`:

```erb
<%= form_with model: contest do |form| %>
  <div>
    <%= label_tag :played_at, "Played at" %>
    <%= datetime_field_tag :played_at, contest.played_at %>
  </div>

  <div>
    <%= label_tag "contest[winner_id]", "First place" %>
    <%= select_tag "contest[winner_id]", options_from_collection_for_select(people, :id, :name) %>
  </div>

  <div>
    <%= label_tag "contest[loser_id]", "Second place" %>
    <%= select_tag "contest[loser_id]", options_from_collection_for_select(people, :id, :name) %>
  </div>

  <div>
    <%= label_tag :tie, "It was a tie" %>
    <%= hidden_field_tag :tie, "0" %>
    <%= check_box_tag :tie, "1" %>
  </div>

  <%= form.submit %>
<% end %>
```

Create `app/views/contests/index.html.erb`:

```erb
<h1>Contests</h1>

<p><%= link_to "Record a contest", new_contest_path %></p>

<table>
  <thead>
    <tr><th>Played</th><th>Outcome</th><th></th></tr>
  </thead>
  <tbody>
    <% @contests.each do |contest| %>
      <% first, second = contest.contest_results.sort_by(&:place) %>
      <tr>
        <td><%= contest.played_at.in_time_zone(LocalZone::NAME).to_fs(:long) %></td>
        <td>
          <% if first.place == second.place %>
            <%= first.person.name %> and <%= second.person.name %> tied
          <% else %>
            <%= first.person.name %> beat <%= second.person.name %>
          <% end %>
        </td>
        <td>
          <%= link_to "Edit", edit_contest_path(contest) %>
          <%= button_to "Remove", contest, method: :delete %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

Create `app/views/contests/new.html.erb`:

```erb
<h1>Record a contest</h1>

<%= render "form", contest: @contest, people: @people %>
```

Create `app/views/contests/edit.html.erb`:

```erb
<h1>Edit contest</h1>

<%= render "form", contest: @contest, people: @people %>
```

- [ ] **Step 5: Run the tests and watch them pass**

```bash
bin/rails test test/controllers/contests_controller_test.rb
```

Expected: 3 runs, 0 failures.

- [ ] **Step 6: Look at it**

Screenshot `/contests` with two contests recorded, one of them a tie.

- [ ] **Step 7: Run the full build and commit**

```bash
bin/ci
git add app/ test/
git commit -m "Add the contest screens"
```

---

### Task 9: The standings screen

**Files:**
- Create: `app/services/read_standings.rb`
- Create: `app/controllers/standings_controller.rb`
- Create: `app/views/standings/show.html.erb`
- Modify: `app/views/layouts/application.html.erb`
- Test: `test/services/read_standings_test.rb`,
  `test/controllers/standings_controller_test.rb`

**Interfaces:**
- Consumes: `StandingsCache` (Task 4).
- Produces: `ReadStandings.call` → `success(rows)`, `StandingsCache` records in
  position order with `person` and their `contest_results` preloaded.

- [ ] **Step 1: Write the failing tests**

Create `test/services/read_standings_test.rb`:

```ruby
require "test_helper"

class ReadStandingsTest < ActiveSupport::TestCase
  test "answers with the rows in position order" do
    first = create_person("a@example.test", 0)
    second = create_person("b@example.test", 1)

    rows = ReadStandings.call.value

    assert_equal [ first.id, second.id ], rows.map(&:person_id),
      "expected position 1 to come back first"
  end

  test "answers with an empty list rather than a refusal when nobody has joined" do
    result = ReadStandings.call

    assert result.success?, "expected an empty standings to be an answer, not a refusal"
    assert_empty result.value
  end

  private
    def create_person(email, offset)
      CreatePerson.call(
        name: "Ann", surname: "Baker", email: email,
        born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 1) + offset
      ).value
    end
end
```

Create `test/controllers/standings_controller_test.rb`:

```ruby
require "test_helper"

class StandingsControllerTest < ActionDispatch::IntegrationTest
  test "shows every person with their position" do
    CreatePerson.call(
      name: "Ann", surname: "Baker", email: "ann@example.test",
      born_on: Date.new(1990, 4, 2), joined_on: Date.new(2026, 1, 1)
    )

    get standings_path

    assert_response :success
    assert_select "td", text: "Ann Baker"
  end

  test "is the root page" do
    get root_path

    assert_response :success
  end
end
```

- [ ] **Step 2: Run them and watch them fail**

```bash
bin/rails test test/services/read_standings_test.rb test/controllers/standings_controller_test.rb
```

Expected: FAIL — `ReadStandings` is not defined.

- [ ] **Step 3: Write the service**

Create `app/services/read_standings.rb`:

```ruby
# Reads the derived standings for the one page that shows them. An empty
# standings is an answer, not a refusal.
class ReadStandings < Service
  def call
    success(StandingsCache.includes(person: :contest_results).order(:position).to_a)
  end
end
```

- [ ] **Step 4: Write the controller**

Create `app/controllers/standings_controller.rb`:

```ruby
class StandingsController < ApplicationController
  def show
    @standings = ReadStandings.call.value
  end
end
```

- [ ] **Step 5: Write the view**

Create `app/views/standings/show.html.erb`:

```erb
<h1>Standings</h1>

<table>
  <thead>
    <tr><th>Position</th><th>Name</th><th>Contests played</th></tr>
  </thead>
  <tbody>
    <% @standings.each do |standing| %>
      <tr>
        <td><%= standing.position %></td>
        <td><%= standing.person.name %> <%= standing.person.surname %></td>
        <td><%= standing.person.contest_results.size %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<% if @standings.empty? %>
  <p>Nobody has joined yet. <%= link_to "Add somebody", new_person_path %>.</p>
<% end %>
```

- [ ] **Step 6: Add navigation to the layout**

Modify `app/views/layouts/application.html.erb`, inserting immediately after the
opening `<body>` tag:

```erb
    <nav>
      <%= link_to "Standings", standings_path %> ·
      <%= link_to "People", people_path %> ·
      <%= link_to "Contests", contests_path %>
    </nav>

    <% if notice %><p class="notice"><%= notice %></p><% end %>
    <% if alert %><p class="alert"><%= alert %></p><% end %>
```

- [ ] **Step 7: Run the tests and watch them pass**

```bash
bin/rails test
```

Expected: the whole suite green.

- [ ] **Step 8: Look at it**

Screenshot `/` with four people and two contests recorded, so the ordering is
visibly not the join order.

- [ ] **Step 9: Run the full build and commit**

```bash
bin/ci
git add app/ test/
git commit -m "Add the standings screen"
```

---

### Task 10: Seeds, decision records and the read-me

**Files:**
- Modify: `db/seeds.rb`
- Create: `docs/decisions/positions-are-derived-from-a-log.md`
- Create: `docs/decisions/a-contest-holds-results.md`
- Create: `docs/decisions/the-brief-is-silent-at-two-edges.md`
- Modify: `docs/decisions/README.md`, `README.md`, `app/services/README.md`

**Interfaces:**
- Consumes: every service.
- Produces: nothing code depends on.

- [ ] **Step 1: Write the seeds**

`bin/ci` runs `db:seed:replant`, so the seeds must be idempotent and must go
through the services rather than writing rows directly — otherwise the standings
are never computed and the seed proves nothing.

Replace `db/seeds.rb`:

```ruby
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

zone = LocalZone.zone

# The brief's worked example: the last person beats the first, so they climb
# half the gap and the loser drops one.
CreateContest.call(
  played_at: zone.parse("2026-03-03 18:00"),
  winner: people.last, loser: people.first, tie: false
)

# A tie between people who are not adjacent: the lower one gains a place.
CreateContest.call(
  played_at: zone.parse("2026-03-05 19:30"),
  winner: people[1], loser: people[4], tie: true
)

puts "Seeded #{Person.count} people and #{Contest.count} contests."
```

- [ ] **Step 2: Run the seeds**

```bash
env RAILS_ENV=test bin/rails db:seed:replant
```

Expected: `Seeded 7 people and 2 contests.`

- [ ] **Step 3: Write the three decision records**

Each follows the shape the decisions read-me sets out — Status, Context,
Decision, Rationale, Trade-offs, Consequences — and each is one claim.

`docs/decisions/positions-are-derived-from-a-log.md` argues: contests are
entered out of play order, the rules are order-dependent, so a stored `position`
moved on each write would make the standings depend on typing order. Rejected
alternatives: a `position` column moved in place; an incremental recompute with a
high-water mark. Trade-off accepted: every write recomputes the whole log.

`docs/decisions/a-contest-holds-results.md` argues: a contest holds a collection
of results rather than two columns, so more than two participants costs a
validation change rather than a migration; and the validation caps it at two
today because the brief gives no rules for more. Rejected alternative:
`winner_id`/`loser_id`/`outcome` on one table.

`docs/decisions/the-brief-is-silent-at-two-edges.md` argues: the brief does not
say how an odd gap rounds, nor what happens when a gap of two sends both moves to
one slot. Ruled: the climb rounds down; the demotion wins the contested slot and
the climb is capped. Reasoning: the one-position drop is stated unconditionally
while the climb is already an approximation. Both are open questions for the
group, and the record says so.

- [ ] **Step 4: List them in the decisions read-me**

Add three rows to the table in `docs/decisions/README.md`, matching the existing
format:

```markdown
| [`positions-are-derived-from-a-log`](positions-are-derived-from-a-log.md) | A position is derived from the contest log, never stored and moved |
| [`a-contest-holds-results`](a-contest-holds-results.md) | A contest holds a collection of results, not two participant columns |
| [`the-brief-is-silent-at-two-edges`](the-brief-is-silent-at-two-edges.md) | Where the brief says nothing, the code still has one answer |
```

- [ ] **Step 5: Describe the application in the read-me**

Modify `README.md`, replacing everything above the `## Requirements` heading with
the text below. Leave the setup, test and CI sections exactly as they are.

```markdown
# Ranked standings

A small Rails application for ranking people from 1 to n by the contests they
play against each other.

Contests are entered out of the order they were played, and the ranking rules
depend on that order — so no position is ever stored and moved. The contests are
the record; the standings are recalculated from all of them after every change.

The code does not use the vocabulary of the pastime: a person is a `Person`, a
match is a `Contest`, a draw is a tie, and the ranked list is the standings
([`docs/decisions/plain-words-in-code.md`](docs/decisions/plain-words-in-code.md)).
The design is written up in
[`docs/specs/2026-08-17-ranked-standings-design.md`](docs/specs/2026-08-17-ranked-standings-design.md).
```

- [ ] **Step 6: Run the full build**

```bash
bin/ci
```

Expected: every step green, including the seeds.

- [ ] **Step 7: Commit**

```bash
git add db/seeds.rb docs/ README.md
git commit -m "Seed a worked example and record the decisions behind the design"
```

---

## Before opening the pull request

- [ ] Reorder and squash the commits into logical sets: schema and models, the
      calculation, the services, the screens, the documents. Verify the squashed
      tree is byte-identical — `git diff <backup> HEAD` must be empty.
- [ ] `bin/ci` green from a clean checkout.
- [ ] Screenshots of all three screens attached.
- [ ] Open as a draft: `gh pr create --draft`.
