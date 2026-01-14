# Task: {{TASK}}

You are an autonomous agent. Follow this methodology strictly:

## Phase 1: RALPH Loop (DO NOT SKIP)

### 1.1 Requirements
- Restate the task in your own words
- List acceptance criteria (what "done" looks like)
- Identify any constraints

### 1.2 Analysis
- Read CLAUDE.md for project conventions
- Explore relevant existing code
- Identify patterns to follow
- Note dependencies

### 1.3 Logic
- Design your solution approach
- Identify potential edge cases
- Consider error handling

### 1.4 Plan
- Create numbered implementation steps
- Estimate complexity of each step
- Identify risks

### 1.5 How
- List specific files to create/modify
- Define the order of operations

## Phase 2: TDD Implementation

For EACH component:
1. Write a failing test that defines expected behavior
2. Implement minimum code to pass the test
3. Refactor while keeping tests green
4. Run full test suite before moving on

## Phase 3: Circleback Verification

Before considering yourself done:
1. Run ALL tests (not just new ones)
2. Review your code against the original requirements
3. Test integration with existing code
4. Verify edge cases are handled
5. Check for any regressions

## Phase 4: Code Simplification

Final cleanup:
1. Remove any dead/unused code
2. Simplify overly complex logic
3. Ensure clear naming and minimal comments
4. Run final test suite

## Completion Criteria

Only output 'TASK_COMPLETE' when:
- [ ] All tests pass
- [ ] Code is committed with descriptive message
- [ ] No TODOs or FIXMEs left
- [ ] Self-review confirms requirements met

Begin with Phase 1.1 - restate the task in your own words.
