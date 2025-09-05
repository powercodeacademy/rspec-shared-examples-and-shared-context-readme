# RSpec: Shared Examples & Shared Context: Building Descriptive, Maintainable Specs

In this comprehensive guide, you'll learn how to thoughtfully reuse test logic across examples using RSpec's `shared_examples`, `shared_context`, `include_examples`, and `include_context`. We'll explore when these tools enhance your specs' readability and maintainability—and crucially, when they don't.

---

## What Are Shared Examples and Shared Context?

RSpec provides two powerful tools for sharing code across your test suite:

### Shared Examples

Shared examples are a feature in RSpec that let you define a set of tests once and reuse them across multiple example groups. This is especially useful when you have several classes or objects that should all behave in a similar way, and you want to ensure consistency in your specs without duplicating code.

Instead of copying and pasting the same expectations into different spec files, you can write them once as a shared example and include them wherever needed. This helps keep your test suite maintainable and makes it easy to update expectations in one place if the shared behavior changes.

**Purpose**: Reuse expectations and test logic
**Use when**: Multiple classes should behave the same way (behavioral contracts)

```ruby
# Define once
RSpec.shared_examples "a vehicle that can start and stop" do
  it "can start" do
    subject.start
    expect(subject).to be_started
  end

  it "can stop" do
    subject.start
    subject.stop
    expect(subject).not_to be_started
  end
end

# Use in multiple specs
RSpec.describe Car do
  subject { Car.new("Toyota", "Corolla") }
  it_behaves_like "a vehicle that can start and stop"
end

RSpec.describe Bike do
  subject { Bike.new("Trek", "FX 3") }
  it_behaves_like "a vehicle that can start and stop"
end
```

### Shared Context

Shared context is a feature in RSpec that lets you define reusable setup code—such as variables, `let` blocks, `before` hooks, or helper methods—and share it across multiple example groups. This is especially helpful when you have complex or repetitive setup steps that need to be used in several places throughout your test suite.

By extracting common setup into a shared context, you keep your specs DRY and organized, making it easier to maintain and update test environments as your codebase evolves. Shared context is ideal for situations where multiple specs need the same environment, data, or helpers to run their tests.

**Purpose**: Reuse setup code (let, before, helper methods)
**Use when**: You need the same complex setup across multiple specs

```ruby
# Define once
RSpec.shared_context "with authenticated user" do
  let(:current_user) { create(:user, :verified) }

  before do
    sign_in(current_user)
  end
end

# Use in multiple specs
RSpec.describe ProjectsController do
  include_context "with authenticated user"

  it "shows user's projects" do
    get :index
    expect(response).to be_successful
  end
end
```

---

## Quick DAMP Reminder

At Power Home Remodeling, remember **"clarity over cleverness"**. Don't create shared examples just to eliminate repetition—create them when they represent genuine behavioral contracts. A test that's easy to understand is more valuable than one that's perfectly DRY.

**Rule of thumb**: Wait until you have 3+ genuine use cases before creating shared examples.

---

## Building Up Complexity: From Simple to Advanced

Let's start with our vehicle domain and progressively build more sophisticated shared examples and contexts.

### Level 1: Basic Shared Examples

```ruby
# /spec/support/shared_examples.rb
RSpec.shared_examples "a startable vehicle" do
  it "starts when requested" do
    expect { subject.start }.to change { subject.started? }.from(false).to(true)
  end

  it "stops when requested" do
    subject.start
    expect { subject.stop }.to change { subject.started? }.from(true).to(false)
  end
end

# Usage in specs
RSpec.describe Car do
  subject { Car.new("Toyota", "Corolla") }
  it_behaves_like "a startable vehicle"
end

RSpec.describe Bike do
  subject { Bike.new("Trek", "FX 3") }
  it_behaves_like "a startable vehicle"
end
```

### Level 2: Parameterized Shared Examples

```ruby
RSpec.shared_examples "a wheeled vehicle" do |expected_wheels|
  it "has the expected number of wheels" do
    expect(subject.wheels).to eq(expected_wheels)
  end

  if expected_wheels > 0
    it "can check tire pressure" do
      expect(subject.tire_pressures.length).to eq(expected_wheels)
    end
  end
end

# Usage with parameters
RSpec.describe Car do
  subject { Car.new("Toyota", "Corolla") }
  it_behaves_like "a wheeled vehicle", 4
end

RSpec.describe Bike do
  subject { Bike.new("Trek", "FX 3") }
  it_behaves_like "a wheeled vehicle", 2
end

RSpec.describe Boat do
  subject { Boat.new("Yamaha", "242X") }
  it_behaves_like "a wheeled vehicle", 0
end
```

### Level 3: Shared Context for Setup

```ruby
RSpec.shared_context "with started vehicle" do
  before { subject.start }
end

RSpec.shared_context "with low fuel" do
  before { subject.fuel_level = 5 }
end

# Usage combining contexts
RSpec.describe Car do
  subject { Car.new("Toyota", "Corolla") }

  context "when started and low on fuel" do
    include_context "with started vehicle"
    include_context "with low fuel"

    it "shows low fuel warning" do
      expect(subject.warning_lights).to include(:low_fuel)
    end
  end
end
```

### Level 4: Complex Behavioral Contracts

```ruby
RSpec.shared_examples "handles environmental conditions" do
  it "adjusts performance in rain" do
    subject.weather = :rainy
    efficiency_drop = subject.base_efficiency - subject.current_efficiency
    expect(efficiency_drop).to be > 0
  end

  it "handles extreme temperatures" do
    subject.temperature = -10
    expect { subject.start }.not_to raise_error
    expect(subject.started?).to be true
  end
end
```

---

## Shared Examples vs Shared Context: When to Use What

| Feature            | shared_examples                | shared_context                  |
|--------------------|-------------------------------|---------------------------------|
| Purpose            | Reuse expectations/tests      | Reuse setup (let, before, etc.) |
| Primary Usage      | it_behaves_like, include_examples | include_context              |
| Operates On        | The current `subject`         | Adds variables/methods to group  |
| Example Use Cases  | Validations, permissions, APIs | Auth setup, sample data, helpers |
| When to Use        | Testing behavior contracts    | Complex setup that's reused     |
| Maintenance Impact | High (changes affect all users) | Medium (setup changes)         |

### Decision Framework

**Use shared examples when:**

- Multiple classes should behave exactly the same way
- You're testing a genuine behavioral contract (like "acts as commentable")
- The behavior is stable and unlikely to change
- You have 3+ classes that need the same tests

**Use shared context when:**

- You have complex setup that's repeated across specs
- You need the same let variables or before hooks
- Setup is more than 3-5 lines and used in multiple places
- You want to combine multiple setup scenarios

**Don't use either when:**

- You only have 2 use cases (wait and see if you get a third)
- The behavior might diverge in the future
- It makes the tests harder to understand
- You're just trying to eliminate any repetition

## Understanding the Anti-Pattern: When NOT to Use Shared Examples

Before diving into best practices, let's examine common misuses that make specs harder to understand and maintain.

### Anti-Pattern 1: Over-Parameterization

```ruby
# BAD: Too many parameters make it hard to understand
RSpec.shared_examples "a validatable entity" do |field, valid_value, invalid_values, error_message, validation_type|
  # This is becoming a mini-framework, not a shared example
end

# BETTER: Specific, focused shared examples
RSpec.shared_examples "requires presence" do |field|
  it "is invalid without #{field}" do
    subject.send("#{field}=", nil)
    expect(subject).not_to be_valid
    expect(subject.errors[field]).to include("can't be blank")
  end
end
```

### Anti-Pattern 2: Testing Implementation Details

```ruby
# BAD: Testing how something works instead of what it does
RSpec.shared_examples "uses ActiveRecord callbacks" do
  it "calls the after_save callback" do
    expect(subject).to receive(:some_internal_method)
    subject.save
  end
end

# BETTER: Test the behavior, not the implementation
RSpec.shared_examples "notifies users on save" do
  it "sends notification email when saved" do
    expect { subject.save }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
```

### Anti-Pattern 3: Premature Abstraction

```ruby
# BAD: Creating shared examples for code that's only used twice
# and might diverge in the future
RSpec.shared_examples "a timestamped model" do
  it "has created_at" do
    expect(subject).to respond_to(:created_at)
  end
end

# BETTER: Wait until you have 3+ uses and stable behavior
# Often, these behaviors naturally diverge as requirements evolve
```

---

## When TO Use Shared Examples: The Good Patterns

### Pattern 1: Genuine Behavioral Contracts

Use shared examples when multiple classes implement the same interface or behavior contract:

```ruby
# Real behavioral contract that multiple classes should fulfill
RSpec.shared_examples "acts as commentable" do
  it "allows adding comments" do
    comment = subject.comments.build(content: "Great post!", author: create(:user))
    expect(comment).to be_valid
  end

  it "returns comments in chronological order" do
    old_comment = subject.comments.create!(content: "First", author: create(:user), created_at: 1.day.ago)
    new_comment = subject.comments.create!(content: "Second", author: create(:user), created_at: 1.hour.ago)

    expect(subject.comments.ordered).to eq([old_comment, new_comment])
  end

  it "allows deleting comments" do
    comment = subject.comments.create!(content: "Delete me", author: create(:user))
    expect { comment.destroy }.to change { subject.comments.count }.by(-1)
  end
end

# Used across multiple models that implement commenting
RSpec.describe BlogPost do
  subject { create(:blog_post) }
  it_behaves_like "acts as commentable"
end

RSpec.describe ForumTopic do
  subject { create(:forum_topic) }
  it_behaves_like "acts as commentable"
end
```

### Pattern 2: Complex State Transitions

When multiple classes share complex state management:

```ruby
RSpec.shared_examples "has workflow states" do |initial_state, valid_transitions|
  it "starts in the correct initial state" do
    expect(subject.current_state).to eq(initial_state)
  end

  valid_transitions.each do |from_state, to_states|
    to_states.each do |to_state|
      it "can transition from #{from_state} to #{to_state}" do
        subject.transition_to!(from_state) unless subject.current_state == from_state
        expect { subject.transition_to!(to_state) }.not_to raise_error
        expect(subject.current_state).to eq(to_state)
      end
    end
  end

  it "prevents invalid state transitions" do
    subject.transition_to!(initial_state)
    invalid_state = (valid_transitions[initial_state] || []).first || "invalid_state"
    expect { subject.transition_to!("completely_invalid") }.to raise_error(InvalidTransition)
  end
end

# Usage with specific state machines
RSpec.describe Order do
  subject { create(:order) }

  let(:valid_transitions) do
    {
      "pending" => ["confirmed", "cancelled"],
      "confirmed" => ["shipped", "cancelled"],
      "shipped" => ["delivered"],
      "delivered" => []
    }
  end

  it_behaves_like "has workflow states", "pending", valid_transitions
end
```

---

## Shared Examples vs Shared Context: Detailed Comparison

Understanding when to use each tool is crucial for writing maintainable specs.

| Feature            | shared_examples                | shared_context                  |
|--------------------|-------------------------------|---------------------------------|
| Purpose            | Reuse expectations/tests      | Reuse setup (let, before, etc.) |
| Primary Usage      | it_behaves_like, include_examples | include_context              |
| Operates On        | The current `subject`         | Adds variables/methods to group  |
| Example Use Cases  | Validations, permissions, APIs | Auth setup, sample data, helpers |
| When to Use        | Testing behavior contracts    | Complex setup that's reused     |
| Maintenance Impact | High (changes affect all users) | Medium (setup changes)         |

### Shared Examples Deep Dive

Shared examples are perfect for testing **behavior contracts** - when multiple classes should behave the same way.

#### Simple Vehicle Example (Building Up Complexity)

Let's start with our vehicle example and build complexity gradually:

```ruby
# /spec/support/shared_examples.rb

# Level 1: Basic behavioral contract
RSpec.shared_examples "a startable vehicle" do
  it "starts when requested" do
    expect { subject.start }.to change { subject.started? }.from(false).to(true)
  end

  it "stops when requested" do
    subject.start
    expect { subject.stop }.to change { subject.started? }.from(true).to(false)
  end

  it "cannot start when already started" do
    subject.start
    expect { subject.start }.not_to change { subject.started? }
  end
end

# Level 2: More complex behavioral contract with edge cases
RSpec.shared_examples "a fuel-powered vehicle" do
  it "requires fuel to start" do
    subject.fuel_level = 0
    expect { subject.start }.to raise_error(InsufficientFuelError)
  end

  it "consumes fuel when running" do
    subject.start
    initial_fuel = subject.fuel_level
    subject.run_for(minutes: 30)
    expect(subject.fuel_level).to be < initial_fuel
  end

  it "stops automatically when fuel runs out" do
    subject.fuel_level = 1 # Very low fuel
    subject.start

    expect { subject.run_until_empty }.to change { subject.started? }.to(false)
    expect(subject.fuel_level).to eq(0)
  end
end

# Level 3: Parameterized for different vehicle types
RSpec.shared_examples "a wheeled vehicle" do |expected_wheels|
  it "has the expected number of wheels" do
    expect(subject.wheels).to eq(expected_wheels)
  end

  it "can check tire pressure on all wheels" do
    pressures = subject.check_tire_pressures
    expect(pressures.length).to eq(expected_wheels)
    expect(pressures).to all(be_a(Numeric))
  end

  if expected_wheels > 0
    it "can rotate tires" do
      expect { subject.rotate_tires }.not_to raise_error
    end
  else
    it "cannot rotate tires (no wheels)" do
      expect { subject.rotate_tires }.to raise_error(NoWheelsError)
    end
  end
end
```

#### Using Shared Examples Effectively

```ruby
# /spec/car_spec.rb
require 'rails_helper'

RSpec.describe Car do
  subject { Car.new("Toyota", "Corolla") }

  # Test the basic contract
  it_behaves_like "a startable vehicle"
  it_behaves_like "a fuel-powered vehicle"
  it_behaves_like "a wheeled vehicle", 4

  # Car-specific behavior that doesn't belong in shared examples
  describe "air conditioning" do
    it "cools the interior when AC is on" do
      subject.start
      subject.turn_on_ac
      expect(subject.interior_temperature).to be < subject.exterior_temperature
    end
  end

  describe "trunk storage" do
    it "can store items in the trunk" do
      expect { subject.store_in_trunk("groceries") }.to change { subject.trunk_contents.count }.by(1)
    end
  end
end
```

### Shared Context

Shared context is ideal for **complex setup** that's needed across multiple specs.

#### Authentication Context Example

```ruby
# /spec/support/shared_contexts.rb

RSpec.shared_context "with authenticated user" do
  let(:current_user) { create(:user, :verified) }

  before do
    sign_in(current_user)
  end
end

RSpec.shared_context "with admin user" do
  let(:current_user) { create(:user, :admin) }

  before do
    sign_in(current_user)
  end
end

RSpec.shared_context "with project setup" do
  let(:organization) { create(:organization) }
  let(:project) { create(:project, organization: organization) }
  let(:team_members) { create_list(:user, 3, organization: organization) }

  before do
    team_members.each { |member| project.add_member(member) }
  end
end

# Complex setup combining multiple contexts
RSpec.shared_context "with complete project environment" do
  include_context "with authenticated user"
  include_context "with project setup"

  let(:tasks) { create_list(:task, 5, project: project, assignee: team_members.sample) }
  let(:milestones) { create_list(:milestone, 2, project: project) }

  before do
    # Additional setup specific to this context
    project.add_member(current_user, role: 'project_manager')
    tasks.each { |task| task.milestone = milestones.sample; task.save! }
  end
end
```

#### Using Shared Context Effectively

```ruby
# /spec/controllers/projects_controller_spec.rb
RSpec.describe ProjectsController do
  describe "GET #index" do
    context "when user is authenticated" do
      include_context "with authenticated user"

      it "shows user's projects" do
        get :index
        expect(response).to be_successful
      end
    end

    context "when user is not authenticated" do
      it "redirects to login" do
        get :index
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "POST #create" do
    context "with valid project data" do
      include_context "with authenticated user"

      let(:valid_attributes) { attributes_for(:project) }

      it "creates a new project" do
        expect {
          post :create, params: { project: valid_attributes }
        }.to change(Project, :count).by(1)
      end
    end
  end

  describe "complex workflows" do
    include_context "with complete project environment"

    it "can generate project reports" do
      get :report, params: { id: project.id }
      expect(response).to be_successful
      expect(assigns(:tasks)).to eq(tasks)
      expect(assigns(:milestones)).to eq(milestones)
    end
  end
end
```

---

### Advanced Patterns and Best Practices

#### Pattern 1: Conditional Shared Examples

Sometimes you need shared examples that behave differently based on the context:

```ruby
RSpec.shared_examples "handles file uploads" do
  it "accepts valid file types" do
    valid_file = fixture_file_upload('test.pdf', 'application/pdf')
    subject.file = valid_file
    expect(subject).to be_valid
  end

  it "rejects invalid file types" do
    invalid_file = fixture_file_upload('test.exe', 'application/x-executable')
    subject.file = invalid_file
    expect(subject).not_to be_valid
    expect(subject.errors[:file]).to include("File type not allowed")
  end

  # Conditional behavior based on what's defined in the including spec
  if respond_to?(:max_file_size)
    it "enforces file size limits" do
      allow_any_instance_of(ActionDispatch::Http::UploadedFile).to receive(:size).and_return(max_file_size + 1)
      large_file = fixture_file_upload('test.pdf', 'application/pdf')
      subject.file = large_file
      expect(subject).not_to be_valid
    end
  end
end

# Usage:
RSpec.describe DocumentUpload do
  subject { DocumentUpload.new }
  let(:max_file_size) { 10.megabytes }

  it_behaves_like "handles file uploads"
end

RSpec.describe ImageUpload do
  subject { ImageUpload.new }
  # No max_file_size defined, so size test won't run

  it_behaves_like "handles file uploads"
end
```

#### Pattern 2: Nested Shared Examples for Complex Hierarchies

```ruby
RSpec.shared_examples "a publishable content" do
  it_behaves_like "has timestamps"
  it_behaves_like "has workflow states", "draft", {
    "draft" => ["published", "archived"],
    "published" => ["archived", "draft"],
    "archived" => ["draft"]
  }

  describe "publication" do
    it "sets published_at when published" do
      subject.publish!
      expect(subject.published_at).to be_within(1.second).of(Time.current)
    end

    it "clears published_at when unpublished" do
      subject.publish!
      subject.unpublish!
      expect(subject.published_at).to be_nil
    end
  end

  describe "SEO" do
    it "generates meta description from content" do
      subject.content = "This is a long piece of content that should be truncated for SEO purposes."
      expect(subject.meta_description).to eq("This is a long piece of content that should be...")
    end
  end
end

RSpec.shared_examples "has timestamps" do
  it "sets created_at on creation" do
    expect(subject.created_at).to be_within(1.second).of(Time.current)
  end

  it "updates updated_at on save" do
    original_time = subject.updated_at
    sleep(0.1) # Ensure time difference
    subject.touch
    expect(subject.updated_at).to be > original_time
  end
end
```

#### Pattern 3: Shared Examples with Metadata

Use RSpec metadata to create more intelligent shared examples:

```ruby
RSpec.shared_examples "validates required fields", :validation do |*required_fields|
  required_fields.each do |field|
    it "requires #{field}", field: field do
      subject.send("#{field}=", nil)
      expect(subject).not_to be_valid
      expect(subject.errors[field]).to include("can't be blank")
    end
  end
end

RSpec.shared_examples "handles API errors", :api do
  it "handles 404 errors gracefully" do
    stub_request(:get, /example\.com/).to_return(status: 404)
    expect { subject.fetch_data }.to raise_error(NotFoundError)
  end

  it "retries on timeout", :slow do
    stub_request(:get, /example\.com/).to_timeout.then.to_return(status: 200, body: '{"data": "success"}')
    expect(subject.fetch_data).to eq({"data" => "success"})
  end
end

# Usage with metadata filtering
RSpec.describe User do
  subject { build(:user) }

  it_behaves_like "validates required fields", :email, :name

  # Can run only validation tests: rspec --tag validation
end
```

---

## Decision Framework: When to Use What

Use this decision tree to choose the right approach:

### 1. Ask: "Is this behavior or setup?"

**Behavior (what the code does)** → Consider shared examples
**Setup (preparing the test environment)** → Consider shared context

### 2. Ask: "How many places need this?"

- **1 place**: Don't share yet
- **2 places**: Usually don't share (wait and see)
- **3+ places**: Good candidate for sharing
- **5+ places**: Definitely share

### 3. Ask: "How stable is this pattern?"

- **Frequently changing**: Don't share (duplication is better than wrong abstraction)
- **Stable for 3+ months**: Good candidate
- **Core business logic**: Excellent candidate

### 4. Ask: "Does sharing improve or hurt readability?"

```ruby
# HURTS readability - too generic
it_behaves_like "handles data", "POST", "/api/users", { name: "John" }, 201, { id: 1, name: "John" }

# IMPROVES readability - specific and clear
it_behaves_like "creates a user successfully"
```

### 5. Ask: "Is this a genuine behavioral contract?"

**Yes**: Perfect for shared examples
**No**: Probably better as regular tests

---

## Comprehensive Best Practices

### Organization and Structure

```ruby
# Good: Organized in logical files
# /spec/support/shared_examples/
#   ├── api_shared_examples.rb
#   ├── model_shared_examples.rb
#   ├── authentication_shared_examples.rb
#   └── workflow_shared_examples.rb

# /spec/support/shared_contexts/
#   ├── authentication_contexts.rb
#   ├── database_contexts.rb
#   └── api_contexts.rb
```

### Naming Conventions

```ruby
# GOOD: Descriptive, behavior-focused names
RSpec.shared_examples "acts as commentable"
RSpec.shared_examples "validates email format"
RSpec.shared_examples "handles API timeouts gracefully"

# BAD: Generic, implementation-focused names
RSpec.shared_examples "model tests"
RSpec.shared_examples "validation checks"
RSpec.shared_examples "API stuff"
```

### Documentation Standards

```ruby
# Always document complex shared examples
RSpec.shared_examples "processes payment transactions" do |payment_method|
  # This shared example tests the complete payment processing flow
  # including validation, external API calls, and state transitions.
  #
  # Required context:
  # - subject: must respond to #process_payment
  # - let(:amount): the payment amount in cents
  # - let(:customer): a valid customer object
  #
  # Parameters:
  # - payment_method: :credit_card, :bank_transfer, or :paypal
  #
  # Example usage:
  #   RSpec.describe PaymentProcessor do
  #     subject { PaymentProcessor.new(customer: customer, amount: amount) }
  #     let(:amount) { 5000 }
  #     let(:customer) { create(:customer, :verified) }
  #
  #     it_behaves_like "processes payment transactions", :credit_card
  #   end

  context "with #{payment_method} payment method" do
    # ... test implementation
  end
end
```

### Error Handling in Shared Examples

```ruby
RSpec.shared_examples "handles validation errors gracefully" do
  # Ensure the including spec provides necessary setup
  before do
    raise "Must define 'invalid_attributes' in including spec" unless defined?(invalid_attributes)
  end

  it "provides clear error messages" do
    subject.attributes = invalid_attributes
    expect(subject).not_to be_valid
    expect(subject.errors.full_messages).to all(be_a(String))
    expect(subject.errors.full_messages).not_to be_empty
  end
end
```

### Performance Considerations

```ruby
# BAD: Expensive setup in shared examples
RSpec.shared_examples "processes large datasets" do
  before do
    # This runs for every including spec!
    create_list(:record, 10_000)
  end
end

# GOOD: Lazy loading and efficient setup
RSpec.shared_examples "processes large datasets" do
  let(:large_dataset) { create_list(:record, 100) } # Smaller, more manageable
  # Or even better, use factories with build_stubbed for non-persisted objects
end
```

---

## Common Pitfalls and How to Avoid Them

### Pitfall 1: The God Shared Example

```ruby
# BAD: One shared example trying to do everything
RSpec.shared_examples "complete model behavior" do
  # 200 lines of tests covering everything
end

# GOOD: Focused, single-purpose shared examples
RSpec.shared_examples "validates presence of required fields"
RSpec.shared_examples "handles soft deletion"
RSpec.shared_examples "tracks audit changes"
```

### Pitfall 2: Hidden Dependencies

```ruby
# BAD: Shared example that depends on magic
RSpec.shared_examples "sends notifications" do
  it "sends email notification" do
    # Where does current_user come from? Magic!
    expect { subject.save }.to change { current_user.notifications.count }.by(1)
  end
end

# GOOD: Explicit dependencies
RSpec.shared_examples "sends notifications" do |notification_recipient_method|
  it "sends email notification" do
    recipient = subject.send(notification_recipient_method)
    expect { subject.save }.to change { recipient.notifications.count }.by(1)
  end
end

# Usage: it_behaves_like "sends notifications", :owner
```

### Pitfall 3: Testing the Wrong Level

```ruby
# BAD: Unit test shared examples testing integration concerns
RSpec.shared_examples "API endpoint behavior" do
  it "returns proper HTTP status codes" do
    # This belongs in integration/request specs, not unit tests
  end
end

# GOOD: Keep shared examples at the appropriate level
RSpec.shared_examples "serializable to JSON" do
  it "includes all required fields in JSON output" do
    json = JSON.parse(subject.to_json)
    expect(json).to include("id", "created_at", "updated_at")
  end
end
```

---

## Getting Hands-On

Ready to practice? Here’s how to get started:

1. **Fork and clone this repo to your own GitHub account.**
2. **Install dependencies:**

    ```zsh
    bundle install
    ```

3. **Run the specs:**

    ```zsh
    bin/rspec
    ```

4. **Explore the code:**

   - All lesson code uses the Vehicles domain (see `lib/` and `spec/`).
   - Review the examples for shared_examples and shared_context in `spec/shared_examples_spec.rb`, `spec/car_spec.rb`, `spec/bike_spec.rb`, and `spec/boat_spec.rb`.

5. **Implement the pending specs:**

   - Open `spec/car_spec.rb` and look for specs marked as `pending`.
   - Implement the real methods in the vehicle classes (`lib/car.rb`, etc.) as needed so the pending specs pass.

6. **Re-run the specs** to verify your changes!

**Challenge:** Try writing your own shared example or shared context for a new vehicle feature (e.g., "a vehicle that can honk" or "with a flat tire") and use it in multiple specs.

---

## What's Next?

Lab 4 is next! In Lab 4, you'll organize a larger Ruby class spec suite using contexts, subjects, and shared examples. This is your chance to put all these DRY techniques into practice on a real-world spec structure.

---

## Resources

- [RSpec: Shared Examples](https://relishapp.com/rspec/rspec-core/v/3-10/docs/example-groups/shared-examples)
- [RSpec: Shared Context](https://relishapp.com/rspec/rspec-core/v/3-10/docs/example-groups/shared-context)
- [Better Specs: DRY](https://www.betterspecs.org/#dry)
- [Thoughtbot: DRYing Up RSpec](https://thoughtbot.com/blog/drying-up-rspec)
