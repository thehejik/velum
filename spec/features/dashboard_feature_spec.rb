require "rails_helper"

# rubocop:disable RSpec/ExampleLength
describe "Dashboard" do
  let!(:user) { create(:user) }

  before do
    setup_done
  end

  describe "Downloading kubeconfig" do
    before do
      login_as user, scope: :user

      Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master")
      Minion.create!(minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local", role: "worker")
      setup_stubbed_pending_minions!
      visit authenticated_root_path
    end

    it "enables/disables the download button depending on the current state", js: true do
      # Bootstrapping, the button is disabled.
      expect(page).to have_css("#download-kubeconfig[disabled]")

      # Fake that bootstrapping ended successfully.
      # rubocop:disable Rails/SkipsModelValidations
      Minion.update_all(highstate: Minion.highstates[:applied])
      # rubocop:enable Rails/SkipsModelValidations
      visit authenticated_root_path

      expect(page).to have_css("#download-kubeconfig:not(:disabled)")
    end
  end

  describe "Updating nodes" do
    let!(:minions) do
      Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master" },
                      { minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local", role: "worker" },
                      { minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local", role: "worker" },
                      { minion_id: SecureRandom.hex, fqdn: "minion3.k8s.local" }]
    end

    before do
      login_as user, scope: :user
      setup_stubbed_pending_minions!
      # rubocop:disable Rails/SkipsModelValidations
      Minion.update_all(highstate: Minion.highstates[:applied])
      # rubocop:enable Rails/SkipsModelValidations

      visit authenticated_root_path
    end

    it "A user see the update link if update is available", js: true do
      expect(page).not_to have_content("update all nodes")

      # minion[1].highstate == :applied
      minions[1].update(tx_update_reboot_needed: true, tx_update_failed: false)

      expect(page).to have_content("update all nodes")
      page.save_screenshot("after.png")
    end

    it "A user see the update link if update is available (retryable)", js: true do
      expect(page).not_to have_content("update all nodes")

      minions[1].update(highstate:               Minion.highstates[:failed],
                        tx_update_reboot_needed: true,
                        tx_update_failed:        false)

      expect(page).to have_content("update all nodes")
    end

    it "A user doesn't see link if there's a pending state", js: true do
      # update is available and all minions has applied state
      minions[1].update(tx_update_reboot_needed: true, tx_update_failed: false)

      expect(page).to have_content("update all nodes")

      # one of the minions is pending (bootstrapping or update in progress)
      minions[2].update(highstate: Minion.highstates[:pending])

      # update link hidden
      expect(page).not_to have_content("update all nodes")
    end

    it "A user doesn't see link if there's a admin update available", js: true do
      # admin node update and node are available and all minions has applied state
      # rubocop:disable Rails/SkipsModelValidations
      Minion.where(minion_id: "admin").update_all(tx_update_reboot_needed: true,
                                                  tx_update_failed:        false)
      # rubocop:enable Rails/SkipsModelValidations
      minions[1].update(tx_update_reboot_needed: true, tx_update_failed: false)

      expect(page).to have_content("Admin node is running outdated software")
      expect(page).not_to have_content("update all nodes")
    end

    it "A user doesn't see notification if there's a pending highstate node", js: true do
      # admin node update is available
      # rubocop:disable Rails/SkipsModelValidations
      Minion.where(minion_id: "admin").update_all(tx_update_reboot_needed: true,
                                                  tx_update_failed:        false)
      # rubocop:enable Rails/SkipsModelValidations

      # one of the minions is pending (bootstrapping or update in progress)
      minions[1].update(highstate: Minion.highstates[:pending])

      expect(page).not_to have_content("Admin node is running outdated software")
      expect(page).not_to have_content("update all nodes")
    end

    it "A user doesn't see Accept Node link if there's a pending highstate node", js: true do
      setup_stubbed_pending_minions!(stubbed: [minions[3].minion_id])

      visit authenticated_root_path

      expect(page).to have_content(minions[3].minion_id)
      expect(page).to have_content("Accept | Reject")

      # one of the minions is pending (bootstrapping or update in progress)
      minions[1].update(highstate: Minion.highstates[:pending])

      expect(page).not_to have_content("Accept | Reject")
    end

    it "reject node from pending acceptance state", js: true do
      setup_stubbed_pending_minions!(stubbed: [minions[3].minion_id])

      visit authenticated_root_path

      expect(page).to have_content("Accept | Reject")

      within ".minion_#{minions[3].minion_id}" do
        click_on "Reject"
      end

  #   page.evaluate_script('window.confirm = function() { return true; }')  
  #  expect(page.driver.alert_messages.last).to eq 'Are you sure you want to reject'
  #    page.dismiss_confirm do
  #      click_link 'Cancel'
  #    end
      setup_stubbed_reject_minion!(stubbed: minions[3].minion_id)
      page.driver.browser.switch_to.alert.accept
      expect(page).to have_content("Rejection in progress")
    end

    it "A user doesn't see (new) link if there's a pending highstate node", js: true do
      expect(page).to have_content("(new)")

      # one of the minions is pending (bootstrapping or update in progress)
      minions[1].update(highstate: Minion.highstates[:pending])

      expect(page).not_to have_content("(new)")
    end

    context "when unsupported configuration" do
      before do
        Minion.where.not(minion_id: "admin").destroy_all
      end
      it "shows alert if nodes is less than 3", js: true do
        Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master" },
                        { minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local", role: "worker" }]

        visit authenticated_root_path
        expect(page).to have_content("requires a minimum of three nodes")
      end

      it "shows alert if masters number is even", js: true do
        Minion.create! [{ minion_id: SecureRandom.hex, fqdn: "minion0.k8s.local", role: "master" },
                        { minion_id: SecureRandom.hex, fqdn: "minion1.k8s.local", role: "master" },
                        { minion_id: SecureRandom.hex, fqdn: "minion2.k8s.local", role: "worker" }]

        visit authenticated_root_path
        expect(page).to have_content("requires an odd number of masters")
      end
    end
  end
end
# rubocop:enable RSpec/ExampleLength
