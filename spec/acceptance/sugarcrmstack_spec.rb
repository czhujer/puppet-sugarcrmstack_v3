require 'spec_helper_acceptance'

describe 'sugarcrmstack' do
  it 'works idempotently with no errors' do
    pp = 'include sugarcrmstack'

    # Run it twice and test for idempotency
    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes: true)
  end

  #describe service('httpd') do
  #  it { is_expected.to be_running }
  #  it { is_expected.to be_enabled }
  #end
end
