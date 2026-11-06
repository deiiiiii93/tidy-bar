import Testing
@testable import TidyBarCore

@Test func firstLaunchIsVisibleAndManual() {
    let policy = VisibilityPolicy()
    #expect(!policy.isHidden)
    #expect(policy.timerTicket == nil)
}

@Test func autoHideOnlyFiresForCurrentReveal() {
    var policy = VisibilityPolicy()
    policy.configure(delay: 10, suspended: false)
    let oldTicket = policy.timerTicket!
    policy.setHidden(true)
    policy.setHidden(false)
    let fired1 = policy.autoHide(ticket: oldTicket)
    #expect(!fired1)
    #expect(!policy.isHidden)
    let fired2 = policy.autoHide(ticket: policy.timerTicket!)
    #expect(fired2)
    #expect(policy.isHidden)
    #expect(policy.timerTicket == nil)
}

@Test func settingsSuspendsAndInvalidatesTimer() {
    var policy = VisibilityPolicy()
    policy.configure(delay: 30, suspended: false)
    let ticket = policy.timerTicket!
    policy.configure(delay: 30, suspended: true)
    #expect(policy.timerTicket == nil)
    let fired3 = policy.autoHide(ticket: ticket)
    #expect(!fired3)
    policy.configure(delay: 30, suspended: false)
    #expect(policy.timerTicket != nil)
    let fired4 = policy.autoHide(ticket: ticket)
    #expect(!fired4)
}

@Test func disablingOrChangingDelayInvalidatesTimer() {
    var policy = VisibilityPolicy()
    policy.configure(delay: 10, suspended: false)
    let ticket = policy.timerTicket!
    policy.configure(delay: 60, suspended: false)
    let fired5 = policy.autoHide(ticket: ticket)
    #expect(!fired5)
    let newTicket = policy.timerTicket!
    policy.configure(delay: 0, suspended: false)
    let fired6 = policy.autoHide(ticket: newTicket)
    #expect(!fired6)
    #expect(!policy.isHidden)
}

@Test func negativeDelayNeverSchedules() {
    var policy = VisibilityPolicy()
    policy.configure(delay: -1, suspended: false)
    #expect(policy.delay == 0)
    #expect(policy.timerTicket == nil)
}
