package io.featurehub.android


import io.featurehub.client.ClientContext
import io.featurehub.client.FeatureRepository
import okhttp3.Call
import okhttp3.Request
import spock.lang.Specification

class FeatureHubClientSpec extends Specification {
  Call.Factory client
  Call call;
  FeatureRepository repo
  FeatureHubClient fhc

  def "a null sdk url will never trigger a call"() {
    when: "i initialize the client"
      call = Mock(Call)
      def fhc = new FeatureHubClient(null, null, null, client)
    and: "check for updates"
      fhc.checkForUpdates()
    then:
      0 * client.newCall(_)
  }

  def "a valid host and url will trigger a call when asked"() {
    given: "i validly initialize the client"
      call = Mock(Call)

      client = Mock {
        1 * newCall({ Request r ->
          r.header('x-featurehub') == 'this is a header'
        }) >> call
      }

      repo = Mock {
        1 * clientContext() >> Mock(ClientContext)
      }
      fhc = new FeatureHubClient("http://localhost", ["1234"], repo, client)
    and: "i specify a header"
      fhc.notify("this is a header")
    when: "i check for updates"
      fhc.checkForUpdates()
    then:
      1 == 1
  }

  // can't test any further because okhttp uses too many final classes
}
