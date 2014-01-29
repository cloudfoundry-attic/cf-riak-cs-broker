require 'spec_helper'
require 'hash_to_acl_with_stripping'

describe Fog::Storage::AWS do
  describe '.hash_to_acl' do
    let(:acl) { {
      'Owner' => {
        'ID' => '0062524b446d433c1aa2bc86055c648505e8b5111e1f4c58f316f3485479f033',
        'DisplayName' => 'admin user'
      },
      'AccessControlList' => [
        {
          'Grantee' => {
            'ID' => '0062524b446d433c1aa2bc86055c648505e8b5111e1f4c58f316f3485479f033',
            'DisplayName' => 'admin user'
          },
          'Permission' => 'FULL_CONTROL'
        }
      ]
    } }

    it "strips whitespace between XML tags" do
      xml = %(<?xml version="1.0"?><AccessControlPolicy><Owner><ID>0062524b446d433c1aa2bc86055c648505e8b5111e1f4c58f316f3485479f033</ID><DisplayName>admin user</DisplayName></Owner><AccessControlList><Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser"><ID>0062524b446d433c1aa2bc86055c648505e8b5111e1f4c58f316f3485479f033</ID><DisplayName>admin user</DisplayName></Grantee><Permission>FULL_CONTROL</Permission></Grant></AccessControlList></AccessControlPolicy>)
      expect(described_class.send(:hash_to_acl, acl)).to eq(xml)
    end
  end
end
